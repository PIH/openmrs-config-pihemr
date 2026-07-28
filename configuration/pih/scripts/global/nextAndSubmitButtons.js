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
            // append nextSection and goToNext=true, unless returnUrl already has them (e.g. left over from a prior validation-error submit), in which case update nextSection in place and don't duplicate goToNext=true
            let returnUrl = window.htmlForm.getReturnUrl();
            let hashIndex = returnUrl.indexOf('#');
            let base = hashIndex === -1 ? returnUrl : returnUrl.substring(0, hashIndex);
            let hash = hashIndex === -1 ? '' : returnUrl.substring(hashIndex);

            if (base.match(/[&?]nextSection=[^&]*/)) {
                base = base.replace(/([&?])nextSection=[^&]*/, '$1nextSection=' + nextSection);
            } else {
                base = base + '&nextSection=' + nextSection;
            }

            if (!base.match(/[&?]goToNext=true(&|$)/)) {
                base = base + '&goToNext=true';
            }

            window.htmlForm.setReturnUrl(base + hash);
        }
        window.htmlForm.submitHtmlForm();
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
