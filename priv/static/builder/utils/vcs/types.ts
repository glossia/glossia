export type Context = {
  language: string;
  country?: string;
};

export type SourceContext = Context;
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

export type LocalizationPayload = {
  version: string;
  modules: LocalizationPayloadModule[];
};

export type LocalizationPayloadModule = {
  id: string;
  format: FileFormat;
  localizables: {
    source: LocalizationPayloadSourceLocalizable;
    target: LocalizationPayloadTargetLocalizable[];
  };
};

export type LocalizationPayloadSourceLocalizable =
  LocalizationPayloadLocalizable<SourceContext>;
export type LocalizationPayloadTargetLocalizable =
  LocalizationPayloadLocalizable<TargetContext>;

export type LocalizationPayloadLocalizableChecksum = {
  algorithm: string;
  value: string;
};

export type LocalizationPayloadLocalizable<C extends Context> = {
  id: string;
  context: C;
  checksum: {
    cache_id: string;
    cache?: LocalizationPayloadLocalizableChecksum;
    content?: LocalizationPayloadLocalizableChecksum;
  };
};
