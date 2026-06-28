Describe 'Glossia chart service selectors'
  Include ./deploy/helm/glossia/e2e/kind.sh

  BeforeAll 'glossia_e2e_install_release service-selectors'
  AfterAll 'glossia_e2e_uninstall_release'

  It 'routes services to parent pods'
    When call glossia_e2e_assert_service_selectors
    The status should be success
    The stdout should include 'service selectors ok'
  End
End
