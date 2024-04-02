function setUpNextButton() {
  jq("#next").click(function () {
    window.htmlForm.setReturnUrl(window.htmlForm.getReturnUrl().split('#')[0] + '&goToNext=true#' + window.htmlForm.getReturnUrl().split('#')[1]);
    window.htmlForm.submitHtmlForm();
  });
}

function setUpNextSectionButtons() {
    jq(".nextSection").click(function () {
        let nextSection = jq(this).attr('id');
        if (nextSection) {
            window.htmlForm.setReturnUrl(window.htmlForm.getReturnUrl().split('#')[0] + '&nextSection=' + nextSection + '&goToNext=true#' + window.htmlForm.getReturnUrl().split('#')[1]);
            window.htmlForm.submitHtmlForm();
        }
    });
}

function setUpSubmitButtons() {
  jq("#submit").click(function () {
    window.htmlForm.submitHtmlForm();
  });
}

function setUpNextAndSubmitButtons() {
    setUpNextButton();
    setUpNextSectionButtons();
    setUpSubmitButtons();
}
