import { Application } from "@hotwired/stimulus"
import ModalController from "controllers/modal_controller"

const application = Application.start()
application.register("modal", ModalController)

export { application }
