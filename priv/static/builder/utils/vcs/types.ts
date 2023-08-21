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

export type TranslationRequestPayload = {
  id: string;
  modules: TranslationRequestPayloadModule[];
};

export type TranslationRequestPayloadModule = {
  id: string;
  description?: string;
  format: FileFormat;
  localizables: {
    source: TranslationRequestPayloadItem;
    target: TranslationRequestPayloadItem[];
  };
};

export type TranslationRequestPayloadItem = {
  id: string;
  context: Context;
  checksum: {
    current: {
      algorithm: string;
      value: string;
    };
    cached: {
      id: string;
      algorithm?: string;
      value?: string;
    };
  };
};
