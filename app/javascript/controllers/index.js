import { Application } from "@hotwired/stimulus"
import ModalController from "controllers/modal_controller"
import AutoSubmitController from "controllers/auto_submit_controller"

const application = Application.start()
application.register("modal", ModalController)
application.register("auto-submit", AutoSubmitController)

export { application }
