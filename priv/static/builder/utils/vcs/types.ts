export type Context = {
  language: string;
  country?: string;
};

export type SourceContext = Context & {
  description: string;
};

export type TargetContext = Context;

/**
 * The file format of a file.
 */
export type FileFormat =
  | "markdown"
  | "yaml"
  | "json"
  | "toml"
  | "portable-object"
  | "portable-object-template";

export type LocalizationRequestPayload = {
  id: string;
  modules: LocalizationRequestPayloadModule[];
};

export type LocalizationRequestPayloadModule = {
  id: string;
  format: FileFormat;
  localizables: {
    source: LocalizationRequestPayloadSourceLocalizable;
    target: LocalizationRequestPayloadTargetLocalizable[];
  };
};

export type LocalizationRequestPayloadSourceLocalizable =
  LocalizationRequestPayloadLocalizable<SourceContext>;
export type LocalizationRequestPayloadTargetLocalizable =
  LocalizationRequestPayloadLocalizable<TargetContext>;

export type LocalizationRequestPayloadLocalizableChecksum = {
  algorithm: string;
  value: string;
};

export type LocalizationRequestPayloadLocalizable<C extends Context> = {
  id: string;
  context: C;
  checksum: {
    cache_id: string;
    cache?: LocalizationRequestPayloadLocalizableChecksum;
    content?: LocalizationRequestPayloadLocalizableChecksum;
  };
};
