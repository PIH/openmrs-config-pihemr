function setUpNextButtonForSections(currentSection) {
  jq("#next").click(function () {
    window.htmlForm.getBeforeSubmit().push(function () {
      window.htmlForm.setReturnUrl(
        window.htmlForm.getReturnUrl() + "&goToNextSection=" + currentSection
      );
      return true;
    });

    window.htmlForm.submitHtmlForm();
  });

  jq("#submit").click(function () {
    window.htmlForm.submitHtmlForm();
  });
}