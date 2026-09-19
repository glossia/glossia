package v1alpha1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
)

// AdoptTurnstileWidget binds a CR to an existing Turnstile widget by
// its sitekey (Cloudflare's public identifier for the widget). Unlike
// rule adoption, the operator never rotates the widget's secret on
// adoption because doing so would break every currently-solved token
// the app already accepted; the caller is expected to have provisioned
// the K8s Secret at spec.secretRef out of band before flipping the CR
// to `mode: active`.
type AdoptTurnstileWidget struct {
	// Sitekey is the widget's public sitekey as shown in the Cloudflare
	// dashboard. Set once at adoption; changing it later is treated as
	// an adoption of a different widget.
	Sitekey string `json:"sitekey"`
}

// TurnstileSecretRef points at the Kubernetes Secret the reconciler
// materializes the widget's sitekey + secret into. Namespaced so the
// consuming app can `envFrom` the secret without a network hop back
// to Cloudflare on every pod start.
type TurnstileSecretRef struct {
	// Namespace the Secret lives in. Defaults to the CR's namespace,
	// but since this CRD is cluster-scoped, callers should be explicit
	// about which workload namespace consumes the widget.
	Namespace string `json:"namespace"`
	// Name of the Secret to write. Created with keys `site-key` and
	// `secret-key` (the shape the Glossia chart's turnstile ExternalSecret
	// mirror is built around).
	Name string `json:"name"`
	// SiteKeyKey is the Secret data key the sitekey is written under.
	// +kubebuilder:default=site-key
	SiteKeyKey string `json:"siteKeyKey,omitempty"`
	// SecretKeyKey is the Secret data key the secret is written under.
	// +kubebuilder:default=secret-key
	SecretKeyKey string `json:"secretKeyKey,omitempty"`
}

// CloudflareTurnstileWidgetSpec describes one Turnstile widget at
// /accounts/{account_id}/challenges/widgets. Fields map directly onto
// the Cloudflare widget shape so the reconciler can render a request
// body without translation.
//
// +kubebuilder:validation:XValidation:rule="self.accountId == oldSelf.accountId",message="accountId is immutable"
// +kubebuilder:validation:XValidation:rule="has(self.adopt) || self.createNewWidget == true",message="either adopt.sitekey or createNewWidget=true must be set"
// +kubebuilder:validation:XValidation:rule="!has(oldSelf.adopt) || (has(self.adopt) && self.adopt.sitekey == oldSelf.adopt.sitekey)",message="adopt is immutable once set"
type CloudflareTurnstileWidgetSpec struct {
	// AccountID is the Cloudflare account the widget lives under.
	// Immutable once the CR is created; a widget can't be moved
	// between accounts.
	// +kubebuilder:validation:XValidation:rule="self == oldSelf",message="accountId is immutable"
	AccountID string `json:"accountId"`

	// Name is the human-readable label shown in the Cloudflare
	// dashboard. Kept in sync on every reconcile.
	Name string `json:"name"`

	// Domains is the list of hostnames allowed to render the widget.
	// A siteverify response's hostname field must match one of these
	// for the app-side Turnstile.verify/2 check to succeed.
	// +kubebuilder:validation:MinItems=1
	Domains []string `json:"domains"`

	// Mode is the widget's UI mode. `managed` shows a Cloudflare
	// challenge that adapts to the traffic; `non-interactive` runs
	// silent unless a challenge is needed; `invisible` never shows any
	// UI (used for programmatic clients).
	// +kubebuilder:validation:Enum=managed;non-interactive;invisible
	Mode string `json:"mode"`

	// Region is the widget's data-plane region. `world` is the
	// default and appropriate for most deployments; `china` routes
	// through the mainland China network.
	// +kubebuilder:validation:Enum=world;china
	// +kubebuilder:default=world
	Region string `json:"region,omitempty"`

	// BotFightMode toggles Cloudflare's bot heuristics on top of the
	// widget's own challenge. Defaults off.
	// +kubebuilder:default=false
	BotFightMode bool `json:"botFightMode,omitempty"`

	// Offlabel hides the Cloudflare brand on the widget. Requires a
	// paid Turnstile plan on Cloudflare's side.
	// +kubebuilder:default=false
	Offlabel bool `json:"offlabel,omitempty"`

	// ClearanceLevel controls when Cloudflare issues a cf_clearance
	// cookie after a solve. Defaults to `interactive` — the safest
	// value for a sign-up gate.
	// +kubebuilder:validation:Enum=no_clearance;jschallenge;managed;interactive
	// +kubebuilder:default=interactive
	ClearanceLevel string `json:"clearanceLevel,omitempty"`

	// Mode controls whether the operator makes Cloudflare writes.
	// Defaults to read_only so the first deployment against a live
	// account can prove out the reconcile plan without changing the
	// dashboard.
	// +kubebuilder:default=read_only
	CRMode ReconcileMode `json:"crMode,omitempty"`

	// Paused halts the reconcile loop entirely, including delete
	// processing. Use as a break-glass without editing every other
	// field.
	// +kubebuilder:default=false
	Paused bool `json:"paused,omitempty"`

	// Adopt binds the CR to an existing widget by its sitekey. See
	// AdoptTurnstileWidget's doc for the caveats.
	// +kubebuilder:validation:XValidation:rule="!has(oldSelf) || self == oldSelf",message="adopt is immutable once set"
	Adopt *AdoptTurnstileWidget `json:"adopt,omitempty"`

	// CreateNewWidget lets the reconciler POST a new widget when
	// spec.adopt is unset. Guards against accidental widget creation
	// from a copy-pasted CR: both fields default to their "no" value
	// and the CEL rule above requires one of them explicitly.
	// +kubebuilder:default=false
	CreateNewWidget bool `json:"createNewWidget,omitempty"`

	// RetainOnDelete keeps the Cloudflare widget after the CR is
	// deleted. Defaults to true so a `kubectl delete` on a CR the
	// operator adopted doesn't take down a widget an app is still
	// depending on. Flip to false for widgets the operator itself
	// created and that should follow the CR out of git.
	// +kubebuilder:default=true
	RetainOnDelete bool `json:"retainOnDelete,omitempty"`

	// SecretRef points at the Kubernetes Secret the operator writes
	// the widget's sitekey (and, on first create, the secret) into.
	SecretRef TurnstileSecretRef `json:"secretRef"`
}

// EffectiveMode returns the ReconcileMode the operator should treat as
// active for this reconcile. Read-only is the safe default whenever
// the spec did not set one explicitly.
func (s *CloudflareTurnstileWidgetSpec) EffectiveMode() ReconcileMode {
	if s.CRMode == ReconcileModeActive {
		return ReconcileModeActive
	}
	return ReconcileModeReadOnly
}

type CloudflareTurnstileWidgetStatus struct {
	Conditions         []metav1.Condition `json:"conditions,omitempty" patchStrategy:"merge" patchMergeKey:"type"`
	// ManagedSitekey is the Cloudflare sitekey the operator is
	// managing for this CR. Stamped on the first successful reconcile
	// and never overwritten by a spec.accountId change; the delete
	// path uses this so a mutated CR cannot orphan a widget.
	ManagedSitekey     string        `json:"managedSitekey,omitempty"`
	ManagedAccountID   string        `json:"managedAccountId,omitempty"`
	ObservedGeneration int64         `json:"observedGeneration,omitempty"`
	Mode               ReconcileMode `json:"mode,omitempty"`
	// ProposedChanges is a compact human-readable diff written on
	// read_only reconciles. Empty means the CR + Cloudflare state
	// agree.
	ProposedChanges  string       `json:"proposedChanges,omitempty"`
	Message          string       `json:"message,omitempty"`
	LastReconciledAt *metav1.Time `json:"lastReconciledAt,omitempty"`
	// SecretMaterialized is true when the reconciler has projected the
	// widget's sitekey (and — on first create only — secret) into the
	// Kubernetes Secret at spec.secretRef.
	SecretMaterialized bool `json:"secretMaterialized,omitempty"`
}

// +kubebuilder:object:root=true
// +kubebuilder:subresource:status
// +kubebuilder:resource:scope=Cluster,shortName=cfwidget
// +kubebuilder:printcolumn:name="Account",type="string",JSONPath=".spec.accountId"
// +kubebuilder:printcolumn:name="Mode",type="string",JSONPath=".spec.crMode"
// +kubebuilder:printcolumn:name="Widget",type="string",JSONPath=".status.managedSitekey"
// +kubebuilder:printcolumn:name="Message",type="string",JSONPath=".status.message"
// +kubebuilder:printcolumn:name="Age",type="date",JSONPath=".metadata.creationTimestamp"
type CloudflareTurnstileWidget struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   CloudflareTurnstileWidgetSpec   `json:"spec,omitempty"`
	Status CloudflareTurnstileWidgetStatus `json:"status,omitempty"`
}

// +kubebuilder:object:root=true
type CloudflareTurnstileWidgetList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []CloudflareTurnstileWidget `json:"items"`
}

func init() {
	SchemeBuilder.Register(&CloudflareTurnstileWidget{}, &CloudflareTurnstileWidgetList{})
}

func (in *CloudflareTurnstileWidgetSpec) DeepCopyInto(out *CloudflareTurnstileWidgetSpec) {
	*out = *in
	if in.Domains != nil {
		out.Domains = make([]string, len(in.Domains))
		copy(out.Domains, in.Domains)
	}
	if in.Adopt != nil {
		out.Adopt = &AdoptTurnstileWidget{}
		*out.Adopt = *in.Adopt
	}
	out.SecretRef = in.SecretRef
}

func (in *CloudflareTurnstileWidget) DeepCopyInto(out *CloudflareTurnstileWidget) {
	*out = *in
	out.TypeMeta = in.TypeMeta
	in.ObjectMeta.DeepCopyInto(&out.ObjectMeta)
	in.Spec.DeepCopyInto(&out.Spec)
	in.Status.DeepCopyInto(&out.Status)
}

func (in *CloudflareTurnstileWidget) DeepCopy() *CloudflareTurnstileWidget {
	if in == nil {
		return nil
	}
	out := new(CloudflareTurnstileWidget)
	in.DeepCopyInto(out)
	return out
}

func (in *CloudflareTurnstileWidget) DeepCopyObject() runtime.Object {
	if c := in.DeepCopy(); c != nil {
		return c
	}
	return nil
}

func (in *CloudflareTurnstileWidgetList) DeepCopyInto(out *CloudflareTurnstileWidgetList) {
	*out = *in
	out.TypeMeta = in.TypeMeta
	in.ListMeta.DeepCopyInto(&out.ListMeta)
	if in.Items != nil {
		out.Items = make([]CloudflareTurnstileWidget, len(in.Items))
		for i := range in.Items {
			in.Items[i].DeepCopyInto(&out.Items[i])
		}
	}
}

func (in *CloudflareTurnstileWidgetList) DeepCopy() *CloudflareTurnstileWidgetList {
	if in == nil {
		return nil
	}
	out := new(CloudflareTurnstileWidgetList)
	in.DeepCopyInto(out)
	return out
}

func (in *CloudflareTurnstileWidgetList) DeepCopyObject() runtime.Object {
	if c := in.DeepCopy(); c != nil {
		return c
	}
	return nil
}

func (in *CloudflareTurnstileWidgetStatus) DeepCopyInto(out *CloudflareTurnstileWidgetStatus) {
	*out = *in
	if in.Conditions != nil {
		out.Conditions = make([]metav1.Condition, len(in.Conditions))
		copy(out.Conditions, in.Conditions)
	}
	if in.LastReconciledAt != nil {
		out.LastReconciledAt = in.LastReconciledAt.DeepCopy()
	}
}
