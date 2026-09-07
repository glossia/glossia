export type RootStackParamList = {
  Login: undefined;
  Accounts: undefined;
  Account: {
    handle: string;
    type: string;
    visibility: string;
  };
  ProjectSections: {
    accountHandle: string;
    projectHandle: string;
    projectName: string;
  };
};
