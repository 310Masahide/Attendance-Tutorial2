import { Controller } from "@hotwired/stimulus"

// 隠したファイル欄で選んだファイルの名前を、表示窓に写します
export default class extends Controller {
  static targets = ["input", "name"]

  show() {
    const file = this.inputTarget.files[0]
    this.nameTarget.value = file ? file.name : ""
  }
}
