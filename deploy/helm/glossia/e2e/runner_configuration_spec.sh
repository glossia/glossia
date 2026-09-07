Describe 'Glossia chart runner configuration'
  Include ./deploy/helm/glossia/e2e/kind.sh

  BeforeAll 'glossia_e2e_install_release runner-configuration'
  AfterAll 'glossia_e2e_uninstall_release'

  It 'exposes runner configuration to the parent deployment'
    When call glossia_e2e_assert_runner_configuration
    The status should be success
    The stdout should include 'runner configuration ok'
  End
End
