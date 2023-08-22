export type Context = {
  language: string;
  country?: string;
};

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
  description?: string;
  format: FileFormat;
  localizables: {
    source: LocalizationRequestPayloadLocalizable;
    target: LocalizationRequestPayloadLocalizable[];
  };
};

export type LocalizationRequestPayloadLocalizableChecksum = {
  algorithm: string;
  value: string;
};

export type LocalizationRequestPayloadLocalizable = {
  id: string;
  context: Context;
  checksum: {
    cache_id: string;
    content: {
      current: LocalizationRequestPayloadLocalizableChecksum;
      cached?: LocalizationRequestPayloadLocalizableChecksum;
    };
    context: {
      current: LocalizationRequestPayloadLocalizableChecksum;
      cached?: LocalizationRequestPayloadLocalizableChecksum;
    };
  };
};
