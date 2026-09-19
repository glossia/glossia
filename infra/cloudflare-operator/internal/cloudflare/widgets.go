package cloudflare

import (
	"context"
	"fmt"
	"net/http"
)

// Widget mirrors Cloudflare's Turnstile widget shape. Only the fields
// the operator reads or writes are modeled; anything else Cloudflare
// returns is discarded on decode. `Secret` is only populated by
// Cloudflare on the create response and on RotateSecret; a GET never
// returns it, so callers cannot assume it is present after a plain
// list/get.
type Widget struct {
	Sitekey        string   `json:"sitekey,omitempty"`
	Secret         string   `json:"secret,omitempty"`
	Name           string   `json:"name"`
	Domains        []string `json:"domains"`
	Mode           string   `json:"mode"`
	Region         string   `json:"region,omitempty"`
	BotFightMode   bool     `json:"bot_fight_mode,omitempty"`
	Offlabel       bool     `json:"offlabel,omitempty"`
	ClearanceLevel string   `json:"clearance_level,omitempty"`
	CreatedOn      string   `json:"created_on,omitempty"`
	ModifiedOn     string   `json:"modified_on,omitempty"`
}

// GetWidget fetches a widget by sitekey, returning (nil, nil) on 404 so
// callers can lazily create.
func (c *Client) GetWidget(ctx context.Context, accountID, sitekey string) (*Widget, error) {
	path := fmt.Sprintf("/accounts/%s/challenges/widgets/%s", accountID, sitekey)
	var wrapper struct {
		Result Widget `json:"result"`
	}
	if _, err := c.do(ctx, http.MethodGet, path, nil, &wrapper); err != nil {
		if IsNotFound(err) {
			return nil, nil
		}
		return nil, err
	}
	return &wrapper.Result, nil
}

// ListWidgets returns every widget in the account. Used at adoption
// time when the CR names a widget by human-readable name rather than
// sitekey.
func (c *Client) ListWidgets(ctx context.Context, accountID string) ([]Widget, error) {
	path := fmt.Sprintf("/accounts/%s/challenges/widgets", accountID)
	var wrapper struct {
		Result []Widget `json:"result"`
	}
	if _, err := c.do(ctx, http.MethodGet, path, nil, &wrapper); err != nil {
		return nil, err
	}
	return wrapper.Result, nil
}

// CreateWidget provisions a new Turnstile widget. The response
// includes the freshly-minted `secret`, which is the ONLY chance the
// operator gets to see it — Cloudflare does not return it on
// subsequent GETs. The caller is responsible for materializing that
// secret into a Kubernetes Secret before the create result is
// discarded.
func (c *Client) CreateWidget(ctx context.Context, accountID string, w Widget) (*Widget, error) {
	path := fmt.Sprintf("/accounts/%s/challenges/widgets", accountID)
	var wrapper struct {
		Result Widget `json:"result"`
	}
	if _, err := c.do(ctx, http.MethodPost, path, w, &wrapper); err != nil {
		return nil, err
	}
	return &wrapper.Result, nil
}

// UpdateWidget PATCH-updates the widget's mutable configuration.
// Cloudflare's PATCH does NOT return the secret, so a drift correction
// on config fields never touches the K8s Secret the operator writes.
func (c *Client) UpdateWidget(ctx context.Context, accountID, sitekey string, w Widget) (*Widget, error) {
	path := fmt.Sprintf("/accounts/%s/challenges/widgets/%s", accountID, sitekey)
	var wrapper struct {
		Result Widget `json:"result"`
	}
	if _, err := c.do(ctx, http.MethodPatch, path, w, &wrapper); err != nil {
		return nil, err
	}
	return &wrapper.Result, nil
}

// DeleteWidget removes a widget. Returns nil on 404 so a delete-CR
// finalizer path is idempotent.
func (c *Client) DeleteWidget(ctx context.Context, accountID, sitekey string) error {
	path := fmt.Sprintf("/accounts/%s/challenges/widgets/%s", accountID, sitekey)
	if _, err := c.do(ctx, http.MethodDelete, path, nil, nil); err != nil {
		if IsNotFound(err) {
			return nil
		}
		return err
	}
	return nil
}

// FindWidgetByName returns the widget whose Name matches, or nil.
// Names are not guaranteed unique by Cloudflare — the caller decides
// whether to error on duplicate matches.
func FindWidgetByName(widgets []Widget, name string) []Widget {
	if name == "" {
		return nil
	}
	var out []Widget
	for _, w := range widgets {
		if w.Name == name {
			out = append(out, w)
		}
	}
	return out
}
