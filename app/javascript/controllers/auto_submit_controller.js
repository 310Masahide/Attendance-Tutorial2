import { Controller } from "@hotwired/stimulus"

// 中の select を変えたら、フォームを Turbo 経由で送信します
export default class extends Controller {
  submit() {
    this.element.requestSubmit()
  }
}
