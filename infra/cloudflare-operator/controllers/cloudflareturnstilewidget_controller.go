package controllers

// CloudflareTurnstileWidget reconciler.
//
// Shape mirrors the rate-limit reconciler's safe-first-deploy
// contract:
//
//   - spec.crMode defaults to read_only; in that mode the operator
//     computes the intended diff into status.proposedChanges, writes
//     Ready=False (Reason=ReadOnly), and issues no Cloudflare writes.
//     Widget-side create is skipped, PATCH drift correction is
//     skipped, and the delete branch on the CR does NOT call the
//     Cloudflare DELETE either.
//   - spec.paused halts the loop, including deletion.
//   - spec.adopt.sitekey binds the CR to an existing widget. The
//     operator merges only CR-set config fields on top of the live
//     payload and NEVER rotates the widget secret — the caller is
//     expected to have populated the K8s Secret at spec.secretRef
//     out of band. Adoption of a matching dashboard widget is a
//     genuine zero-change first reconcile.
//   - spec.createNewWidget: true (with no adopt) allows POST create.
//     The create response is Cloudflare's ONLY chance to hand us the
//     secret — we materialize it to spec.secretRef before returning
//     from the reconcile, and mark status.secretMaterialized=true so
//     future reconciles can distinguish "secret is present in the
//     cluster" from "secret exists only on Cloudflare and would be
//     lost if we ever rotated it".
//   - status.managedSitekey and status.managedAccountId are stamped
//     on the first successful active reconcile and never overwritten
//     by a spec mutation, so a spec.accountId change cannot orphan a
//     widget.

import (
	"context"
	"errors"
	"fmt"
	"reflect"
	"sort"
	"time"

	"github.com/go-logr/logr"
	corev1 "k8s.io/api/core/v1"
	kerrors "k8s.io/apimachinery/pkg/api/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/types"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/builder"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/event"
	"sigs.k8s.io/controller-runtime/pkg/log"
	"sigs.k8s.io/controller-runtime/pkg/predicate"

	cfv1alpha1 "github.com/glossia/infra/cloudflare-operator/api/v1alpha1"
	"github.com/glossia/infra/cloudflare-operator/internal/cloudflare"
)

// WidgetAPI is the Cloudflare surface this reconciler needs, extracted
// so tests can substitute a fake without importing net/http.
type WidgetAPI interface {
	GetWidget(ctx context.Context, accountID, sitekey string) (*cloudflare.Widget, error)
	CreateWidget(ctx context.Context, accountID string, w cloudflare.Widget) (*cloudflare.Widget, error)
	UpdateWidget(ctx context.Context, accountID, sitekey string, w cloudflare.Widget) (*cloudflare.Widget, error)
	DeleteWidget(ctx context.Context, accountID, sitekey string) error
}

const widgetFinalizer = "cloudflareturnstilewidget.cloudflare.glossia.ai/finalizer"

// Condition reasons stamped on status.conditions[Ready].
const (
	widgetReasonReconciled    = "Reconciled"
	widgetReasonReadOnly      = "ReadOnly"
	widgetReasonPaused        = "Paused"
	widgetReasonReconcileErr  = "ReconcileError"
	widgetReasonAdoptMissing  = "AdoptMissing"
	widgetReasonRefuseCreate  = "RefuseCreate"
	widgetReasonSecretPending = "SecretMaterializationPending"
)

// +kubebuilder:rbac:groups=cloudflare.glossia.ai,resources=cloudflareturnstilewidgets,verbs=get;list;watch;update;patch
// +kubebuilder:rbac:groups=cloudflare.glossia.ai,resources=cloudflareturnstilewidgets/status,verbs=get;update;patch
// +kubebuilder:rbac:groups=cloudflare.glossia.ai,resources=cloudflareturnstilewidgets/finalizers,verbs=update
// +kubebuilder:rbac:groups="",resources=secrets,verbs=get;create;update;patch

// CloudflareTurnstileWidgetReconciler drives one CR toward its
// Cloudflare-side widget + a Kubernetes Secret at spec.secretRef.
type CloudflareTurnstileWidgetReconciler struct {
	client.Client
	Scheme         *runtime.Scheme
	CF             WidgetAPI
	ResyncInterval time.Duration
}

func (r *CloudflareTurnstileWidgetReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	logger := log.FromContext(ctx).WithValues("cloudflareturnstilewidget", req.Name)

	cr := &cfv1alpha1.CloudflareTurnstileWidget{}
	if err := r.Get(ctx, req.NamespacedName, cr); err != nil {
		return ctrl.Result{}, client.IgnoreNotFound(err)
	}

	if cr.Spec.Paused {
		logger.V(1).Info("reconcile paused (delete branch is held too)")
		msg := "paused"
		if !cr.DeletionTimestamp.IsZero() {
			msg = "paused: delete held"
		}
		return ctrl.Result{RequeueAfter: r.resync()}, r.stampStatus(ctx, cr, widgetStatusUpdate{
			ready:   false,
			reason:  widgetReasonPaused,
			message: msg,
		})
	}

	if !cr.DeletionTimestamp.IsZero() {
		return r.reconcileDelete(ctx, cr, logger)
	}

	added, err := r.ensureFinalizer(ctx, cr)
	if err != nil {
		return ctrl.Result{}, err
	}
	if added {
		// The Update generated a fresh reconcile; return so we don't
		// race the status write against it.
		return ctrl.Result{}, nil
	}

	effective := cr.Spec.EffectiveMode()
	logger = logger.WithValues("mode", effective, "accountId", cr.Spec.AccountID)

	sitekey := cr.Status.ManagedSitekey
	if sitekey == "" && cr.Spec.Adopt != nil {
		sitekey = cr.Spec.Adopt.Sitekey
	}

	var live *cloudflare.Widget
	if sitekey != "" {
		live, err = r.CF.GetWidget(ctx, cr.Spec.AccountID, sitekey)
		if err != nil {
			return r.stampError(ctx, cr, fmt.Errorf("get widget: %w", err))
		}
		if live == nil && cr.Spec.Adopt != nil {
			// Adoption cannot fall back to create — that would silently
			// produce a fresh widget under the CR's control while the
			// operator user is still expecting the dashboard one.
			return ctrl.Result{RequeueAfter: r.resync()}, r.stampStatus(ctx, cr, widgetStatusUpdate{
				ready:   false,
				reason:  widgetReasonAdoptMissing,
				message: fmt.Sprintf("adopt.sitekey %s not found in account %s", sitekey, cr.Spec.AccountID),
			})
		}
	}

	desired := desiredWidget(cr)

	// Read-only branch: compute the diff, never write to Cloudflare
	// nor to the K8s Secret. Adoption-missing case already returned
	// above. Don't stamp managed IDs here — we haven't proven we can
	// apply anything yet, and stamping in read_only would let a stale
	// managedSitekey survive a spec correction before the first
	// active reconcile.
	if effective == cfv1alpha1.ReconcileModeReadOnly {
		proposal := readOnlyProposal(live, desired, cr)
		return ctrl.Result{RequeueAfter: r.resync()}, r.stampStatus(ctx, cr, widgetStatusUpdate{
			ready:           false,
			reason:          widgetReasonReadOnly,
			message:         "read_only: no Cloudflare writes issued",
			proposedChanges: proposal,
		})
	}

	// Active: apply.
	var applied *cloudflare.Widget

	switch {
	case live != nil:
		if widgetDiffers(live, desired) {
			// PATCH does not return the widget's secret, so this does
			// not touch the K8s Secret.
			merged := mergeWidgetForUpdate(live, desired)
			applied, err = r.CF.UpdateWidget(ctx, cr.Spec.AccountID, live.Sitekey, merged)
			if err != nil {
				return r.stampError(ctx, cr, fmt.Errorf("update widget: %w", err))
			}
			logger.Info("updated widget", "sitekey", applied.Sitekey)
		} else {
			applied = live
		}

	case cr.Spec.CreateNewWidget:
		created, err := r.CF.CreateWidget(ctx, cr.Spec.AccountID, desired)
		if err != nil {
			return r.stampError(ctx, cr, fmt.Errorf("create widget: %w", err))
		}
		if created.Sitekey == "" || created.Secret == "" {
			return r.stampError(ctx, cr, errors.New("create widget: cloudflare response missing sitekey or secret"))
		}
		if err := r.writeWidgetSecret(ctx, cr, created.Sitekey, created.Secret); err != nil {
			return r.stampError(ctx, cr, fmt.Errorf("materialize secret: %w", err))
		}
		applied = created
		logger.Info("created widget + materialized secret", "sitekey", applied.Sitekey, "secretRef", cr.Spec.SecretRef.Name)

	default:
		// No adopt, no createNewWidget, no live widget — refuse to POST
		// so a paste-typo CR cannot produce a spurious widget.
		return ctrl.Result{RequeueAfter: r.resync()}, r.stampStatus(ctx, cr, widgetStatusUpdate{
			ready:   false,
			reason:  widgetReasonRefuseCreate,
			message: "no widget found and createNewWidget=false; refusing to create",
		})
	}

	// Ensure the K8s Secret carries the (possibly refreshed) sitekey.
	// On the create branch we already wrote sitekey + secret above;
	// upsertSecret merges, so this is a no-op there. For adopted
	// widgets this is the ONLY way the sitekey reaches the cluster —
	// the widget secret is unrecoverable from GET/PATCH, so the
	// operator user is expected to have provisioned the secret-key
	// value out of band.
	if err := r.writeWidgetSitekeyOnly(ctx, cr, applied.Sitekey); err != nil {
		return r.stampError(ctx, cr, fmt.Errorf("materialize sitekey: %w", err))
	}

	// secretMaterialized on status means "both keys present in the
	// referenced Secret" — the shape a consumer's envFrom needs. On
	// create we know both are set. On adopt we have to read the
	// Secret back to know whether the operator user already
	// populated the widget secret half.
	bothPresent := cr.Spec.CreateNewWidget
	if !bothPresent {
		bothPresent, err = r.bothKeysPresent(ctx, cr)
		if err != nil {
			return r.stampError(ctx, cr, fmt.Errorf("inspect materialized secret: %w", err))
		}
	}

	msg := "widget reconciled"
	reason := widgetReasonReconciled
	if !bothPresent {
		// Ready=True because Cloudflare state matches spec; but flag
		// the incomplete Secret in the condition reason so a Flux or
		// Argo health check surfaces it and the app doesn't ship
		// unaware.
		reason = widgetReasonSecretPending
		msg = "widget reconciled; secret-key not yet populated in target Secret"
	}

	return ctrl.Result{RequeueAfter: r.resync()}, r.stampStatus(ctx, cr, widgetStatusUpdate{
		ready:              bothPresent,
		reason:             reason,
		message:            msg,
		managedSitekey:     applied.Sitekey,
		managedAccountID:   true,
		advanceGeneration:  bothPresent,
		secretMaterialized: bothPresent,
	})
}

func (r *CloudflareTurnstileWidgetReconciler) reconcileDelete(
	ctx context.Context,
	cr *cfv1alpha1.CloudflareTurnstileWidget,
	logger logr.Logger,
) (ctrl.Result, error) {
	// Determine the sitekey to delete: prefer the stamped
	// managedSitekey (which is immune to spec mutation) and fall back
	// to spec.adopt.sitekey. If neither, there's nothing on the
	// Cloudflare side to delete.
	sitekey := cr.Status.ManagedSitekey
	accountID := cr.Status.ManagedAccountID
	if accountID == "" {
		accountID = cr.Spec.AccountID
	}
	if sitekey == "" && cr.Spec.Adopt != nil {
		sitekey = cr.Spec.Adopt.Sitekey
	}

	// Retain-on-delete OR read_only: never touch Cloudflare, drop
	// finalizer so kube-apiserver can garbage-collect the CR.
	if cr.Spec.RetainOnDelete || cr.Spec.EffectiveMode() == cfv1alpha1.ReconcileModeReadOnly {
		logger.V(1).Info("delete: retained on Cloudflare per spec")
		return ctrl.Result{}, r.dropFinalizer(ctx, cr)
	}

	if sitekey != "" {
		if err := r.CF.DeleteWidget(ctx, accountID, sitekey); err != nil {
			return ctrl.Result{}, fmt.Errorf("delete widget: %w", err)
		}
		logger.Info("deleted widget", "sitekey", sitekey)
	}
	return ctrl.Result{}, r.dropFinalizer(ctx, cr)
}

// desiredWidget renders the Cloudflare widget shape the operator wants
// on the API from the CR spec.
func desiredWidget(cr *cfv1alpha1.CloudflareTurnstileWidget) cloudflare.Widget {
	return cloudflare.Widget{
		Name:           cr.Spec.Name,
		Domains:        append([]string(nil), cr.Spec.Domains...),
		Mode:           cr.Spec.Mode,
		Region:         cr.Spec.Region,
		BotFightMode:   cr.Spec.BotFightMode,
		Offlabel:       cr.Spec.Offlabel,
		ClearanceLevel: cr.Spec.ClearanceLevel,
	}
}

// mergeWidgetForUpdate builds the PATCH body for an update. Only CR-
// managed fields are set; anything Cloudflare stores that the operator
// does not model round-trips because the API's PATCH does not
// overwrite unset fields.
func mergeWidgetForUpdate(live *cloudflare.Widget, desired cloudflare.Widget) cloudflare.Widget {
	out := desired
	// Preserve the live sitekey — PATCH is by-URL so this field is
	// nominal, but keeping it in the body avoids the "Cloudflare
	// mints a new sitekey" edge case if the API ever changes.
	out.Sitekey = live.Sitekey
	// Explicitly do NOT copy live.Secret; the operator must not
	// echo it back on updates.
	out.Secret = ""
	return out
}

// widgetDiffers reports whether the CR-managed fields disagree with
// the live payload. Cloudflare-set fields the CR does not model are
// ignored.
func widgetDiffers(live *cloudflare.Widget, desired cloudflare.Widget) bool {
	if live == nil {
		return true
	}
	if live.Name != desired.Name ||
		live.Mode != desired.Mode ||
		live.Region != desired.Region ||
		live.BotFightMode != desired.BotFightMode ||
		live.Offlabel != desired.Offlabel ||
		live.ClearanceLevel != desired.ClearanceLevel {
		return true
	}
	return !stringSlicesEqualUnordered(live.Domains, desired.Domains)
}

func stringSlicesEqualUnordered(a, b []string) bool {
	if len(a) != len(b) {
		return false
	}
	as := append([]string(nil), a...)
	bs := append([]string(nil), b...)
	sort.Strings(as)
	sort.Strings(bs)
	return reflect.DeepEqual(as, bs)
}

// readOnlyProposal renders a compact human-readable diff for status.
func readOnlyProposal(live *cloudflare.Widget, desired cloudflare.Widget, cr *cfv1alpha1.CloudflareTurnstileWidget) string {
	if live == nil {
		if cr.Spec.CreateNewWidget {
			return fmt.Sprintf("create widget name=%q mode=%q domains=%v", desired.Name, desired.Mode, desired.Domains)
		}
		return "no live widget and createNewWidget=false; nothing would be applied"
	}
	if !widgetDiffers(live, desired) {
		return ""
	}
	return fmt.Sprintf("update widget sitekey=%s (name/mode/domains/region/clearance drift)", live.Sitekey)
}

// writeWidgetSecret creates or updates the target Secret with BOTH
// site-key and secret-key. Called only on the create-new-widget path,
// where Cloudflare hands us the secret in the POST response.
func (r *CloudflareTurnstileWidgetReconciler) writeWidgetSecret(
	ctx context.Context,
	cr *cfv1alpha1.CloudflareTurnstileWidget,
	sitekey, secret string,
) error {
	sk := siteKeyDataKey(cr)
	kk := secretKeyDataKey(cr)
	return r.upsertSecret(ctx, cr, map[string][]byte{
		sk: []byte(sitekey),
		kk: []byte(secret),
	})
}

// writeWidgetSitekeyOnly writes just the sitekey — for adopted widgets
// where the operator does not know the secret (and cannot rotate
// without breaking the app).
func (r *CloudflareTurnstileWidgetReconciler) writeWidgetSitekeyOnly(
	ctx context.Context,
	cr *cfv1alpha1.CloudflareTurnstileWidget,
	sitekey string,
) error {
	sk := siteKeyDataKey(cr)
	return r.upsertSecret(ctx, cr, map[string][]byte{
		sk: []byte(sitekey),
	})
}

func (r *CloudflareTurnstileWidgetReconciler) upsertSecret(
	ctx context.Context,
	cr *cfv1alpha1.CloudflareTurnstileWidget,
	data map[string][]byte,
) error {
	name := types.NamespacedName{
		Namespace: cr.Spec.SecretRef.Namespace,
		Name:      cr.Spec.SecretRef.Name,
	}
	existing := &corev1.Secret{}
	err := r.Get(ctx, name, existing)
	switch {
	case kerrors.IsNotFound(err):
		fresh := &corev1.Secret{
			ObjectMeta: metav1.ObjectMeta{
				Namespace: name.Namespace,
				Name:      name.Name,
				Labels: map[string]string{
					"app.kubernetes.io/managed-by": "cloudflare-operator",
					"cloudflare.glossia.ai/widget": cr.Name,
				},
			},
			Type: corev1.SecretTypeOpaque,
			Data: data,
		}
		return r.Create(ctx, fresh)
	case err != nil:
		return fmt.Errorf("get %s/%s: %w", name.Namespace, name.Name, err)
	}

	// Merge instead of replace so a caller who set additional keys
	// out of band (e.g. an old widget secret provisioned via Infisical
	// on adoption) does not have them wiped.
	if existing.Data == nil {
		existing.Data = map[string][]byte{}
	}
	changed := false
	for k, v := range data {
		if !bytesEqual(existing.Data[k], v) {
			existing.Data[k] = v
			changed = true
		}
	}
	if !changed {
		return nil
	}
	if existing.Labels == nil {
		existing.Labels = map[string]string{}
	}
	existing.Labels["app.kubernetes.io/managed-by"] = "cloudflare-operator"
	existing.Labels["cloudflare.glossia.ai/widget"] = cr.Name
	return r.Update(ctx, existing)
}

// bothKeysPresent reports whether the target Secret has non-empty
// values under both the sitekey and secret-key entries.
func (r *CloudflareTurnstileWidgetReconciler) bothKeysPresent(
	ctx context.Context,
	cr *cfv1alpha1.CloudflareTurnstileWidget,
) (bool, error) {
	name := types.NamespacedName{
		Namespace: cr.Spec.SecretRef.Namespace,
		Name:      cr.Spec.SecretRef.Name,
	}
	existing := &corev1.Secret{}
	err := r.Get(ctx, name, existing)
	switch {
	case kerrors.IsNotFound(err):
		return false, nil
	case err != nil:
		return false, err
	}
	return len(existing.Data[siteKeyDataKey(cr)]) > 0 &&
		len(existing.Data[secretKeyDataKey(cr)]) > 0, nil
}

func siteKeyDataKey(cr *cfv1alpha1.CloudflareTurnstileWidget) string {
	if cr.Spec.SecretRef.SiteKeyKey != "" {
		return cr.Spec.SecretRef.SiteKeyKey
	}
	return "site-key"
}

func secretKeyDataKey(cr *cfv1alpha1.CloudflareTurnstileWidget) string {
	if cr.Spec.SecretRef.SecretKeyKey != "" {
		return cr.Spec.SecretRef.SecretKeyKey
	}
	return "secret-key"
}

func bytesEqual(a, b []byte) bool {
	if len(a) != len(b) {
		return false
	}
	for i := range a {
		if a[i] != b[i] {
			return false
		}
	}
	return true
}

// ensureFinalizer is a per-reconciler helper (the shared ruleset one
// uses a rule-scoped finalizer name).
func (r *CloudflareTurnstileWidgetReconciler) ensureFinalizer(
	ctx context.Context,
	cr *cfv1alpha1.CloudflareTurnstileWidget,
) (bool, error) {
	for _, f := range cr.Finalizers {
		if f == widgetFinalizer {
			return false, nil
		}
	}
	cr.Finalizers = append(cr.Finalizers, widgetFinalizer)
	if err := r.Update(ctx, cr); err != nil {
		return false, fmt.Errorf("add finalizer: %w", err)
	}
	return true, nil
}

func (r *CloudflareTurnstileWidgetReconciler) dropFinalizer(
	ctx context.Context,
	cr *cfv1alpha1.CloudflareTurnstileWidget,
) error {
	filtered := cr.Finalizers[:0]
	for _, f := range cr.Finalizers {
		if f != widgetFinalizer {
			filtered = append(filtered, f)
		}
	}
	cr.Finalizers = filtered
	if err := r.Update(ctx, cr); err != nil {
		return fmt.Errorf("drop finalizer: %w", err)
	}
	return nil
}

func (r *CloudflareTurnstileWidgetReconciler) resync() time.Duration {
	if r.ResyncInterval > 0 {
		return r.ResyncInterval
	}
	return defaultResyncInterval
}

// widgetStatusUpdate captures the fields a single stamping call may
// change. Zero-valued fields are left as-is on the CR status.
type widgetStatusUpdate struct {
	ready              bool
	reason             string
	message            string
	proposedChanges    string
	managedSitekey     string
	managedAccountID   bool
	advanceGeneration  bool
	secretMaterialized bool
}

func (r *CloudflareTurnstileWidgetReconciler) stampStatus(
	ctx context.Context,
	cr *cfv1alpha1.CloudflareTurnstileWidget,
	u widgetStatusUpdate,
) error {
	now := metav1Now()
	cr.Status.Mode = cr.Spec.EffectiveMode()
	cr.Status.Message = u.message
	cr.Status.ProposedChanges = u.proposedChanges
	cr.Status.LastReconciledAt = &now
	if u.managedSitekey != "" {
		cr.Status.ManagedSitekey = u.managedSitekey
	}
	if u.managedAccountID && cr.Status.ManagedAccountID == "" {
		cr.Status.ManagedAccountID = cr.Spec.AccountID
	}
	if u.advanceGeneration {
		cr.Status.ObservedGeneration = cr.Generation
	}
	if u.secretMaterialized {
		cr.Status.SecretMaterialized = true
	}
	condStatus := metav1.ConditionFalse
	if u.ready {
		condStatus = metav1.ConditionTrue
	}
	setReadyCondition(&cr.Status.Conditions, condStatus, u.reason, u.message, now)
	if err := r.Status().Update(ctx, cr); err != nil {
		return fmt.Errorf("update status: %w", err)
	}
	return nil
}

func (r *CloudflareTurnstileWidgetReconciler) stampError(
	ctx context.Context,
	cr *cfv1alpha1.CloudflareTurnstileWidget,
	rerr error,
) (ctrl.Result, error) {
	msg := rerr.Error()
	// Best-effort status write; caller returns the underlying error
	// so controller-runtime backs off with exponential requeue.
	_ = r.stampStatus(ctx, cr, widgetStatusUpdate{
		ready:   false,
		reason:  widgetReasonReconcileErr,
		message: msg,
	})
	return ctrl.Result{}, rerr
}

func setReadyCondition(conds *[]metav1.Condition, status metav1.ConditionStatus, reason, message string, now metav1.Time) {
	for i := range *conds {
		if (*conds)[i].Type == "Ready" {
			if (*conds)[i].Status != status || (*conds)[i].Reason != reason || (*conds)[i].Message != message {
				(*conds)[i].Status = status
				(*conds)[i].Reason = reason
				(*conds)[i].Message = message
				(*conds)[i].LastTransitionTime = now
			}
			return
		}
	}
	*conds = append(*conds, metav1.Condition{
		Type:               "Ready",
		Status:             status,
		Reason:             reason,
		Message:            message,
		LastTransitionTime: now,
	})
}

// SetupWithManager wires the reconciler with a generation-only
// predicate so status patches don't feed back into the queue.
func (r *CloudflareTurnstileWidgetReconciler) SetupWithManager(mgr ctrl.Manager) error {
	pred := predicate.Or(
		predicate.GenerationChangedPredicate{},
		predicate.Funcs{
			DeleteFunc:  func(e event.DeleteEvent) bool { return true },
			GenericFunc: func(e event.GenericEvent) bool { return false },
		},
	)
	return ctrl.NewControllerManagedBy(mgr).
		For(&cfv1alpha1.CloudflareTurnstileWidget{}, builder.WithPredicates(pred)).
		Complete(r)
}

