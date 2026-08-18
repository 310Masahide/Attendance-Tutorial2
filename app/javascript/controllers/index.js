import { Application } from "@hotwired/stimulus"
import EditBasicInfoController from "controllers/edit_basic_info_controller"

const application = Application.start()
application.register("edit-basic-info", EditBasicInfoController)

export { application }
