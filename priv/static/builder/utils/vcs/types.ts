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
    source: LocalizationRequestPayloadItem;
    target: LocalizationRequestPayloadItem[];
  };
};

export type LocalizationRequestPayloadItem = {
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
