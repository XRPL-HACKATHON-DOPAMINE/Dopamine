const FormReset = {
  mounted() {
    this.handleEvent("reset_form", () => {
      this.el.reset();
    });
  }
};

export default FormReset;
