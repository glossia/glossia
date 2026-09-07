Describe 'Glossia chart deployment'
  Include ./deploy/helm/glossia/e2e/kind.sh

  BeforeAll 'glossia_e2e_install_release deployment'
  AfterAll 'glossia_e2e_uninstall_release'

  It 'installs the parent deployment and runner service account'
    When call glossia_e2e_assert_deployment
    The status should be success
    The stdout should include 'deployment ok'
  End
End
