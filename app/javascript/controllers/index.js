import { Application } from "@hotwired/stimulus"
import EditBasicInfoController from "controllers/edit_basic_info_controller"
import OvertimeRequestController from "controllers/overtime_request_controller"

const application = Application.start()
application.register("edit-basic-info", EditBasicInfoController)
application.register("overtime-request", OvertimeRequestController)

export { application }
