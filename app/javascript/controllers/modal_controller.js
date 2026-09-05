import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // NOTE: 送信結果を待たずに閉じる。失敗時は create.turbo_stream.erb が modal を再描画する
  submit() {
    this.close()
  }

  close() {
    this.element.remove()
  }
}
