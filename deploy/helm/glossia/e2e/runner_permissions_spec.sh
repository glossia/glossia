Describe 'Glossia chart runner permissions'
  Include ./deploy/helm/glossia/e2e/kind.sh

  BeforeAll 'glossia_e2e_install_release runner-permissions'
  AfterAll 'glossia_e2e_uninstall_release'

  It 'grants the runner service account pod permissions'
    When call glossia_e2e_assert_runner_permissions
    The status should be success
    The stdout should include 'runner permissions ok'
  End
End
