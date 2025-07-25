{
  lib,
  buildPythonPackage,
  fetchPypi,
  mock,
  pytest-asyncio,
  pytestCheckHook,
  pythonOlder,
  twisted,
  zope-interface,
}:

buildPythonPackage rec {
  pname = "txaio";
  version = "25.6.1";
  format = "setuptools";

  disabled = pythonOlder "3.7";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-2MA9yoI1Fcm8qSDfM1BJI65U8tq/R2zFqe1cwWke1oc=";
  };

  propagatedBuildInputs = [
    twisted
    zope-interface
  ];

  nativeCheckInputs = [
    mock
    pytest-asyncio
    pytestCheckHook
  ];

  disabledTests = [
    # No real value
    "test_sdist"
    # Some tests seems out-dated and require additional data
    "test_as_future"
    "test_errback"
    "test_create_future"
    "test_callback"
    "test_immediate_result"
    "test_cancel"
  ];

  pythonImportsCheck = [ "txaio" ];

  meta = with lib; {
    description = "Utilities to support code that runs unmodified on Twisted and asyncio";
    homepage = "https://github.com/crossbario/txaio";
    changelog = "https://github.com/crossbario/txaio/blob/v${version}/docs/releases.rst";
    license = licenses.mit;
    maintainers = [ ];
  };
}
