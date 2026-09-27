module BulkStatusUpdatable
  extend ActiveSupport::Concern

  # 上長が一括で切り替えられるステータス
  SELECTABLE_STATUSES = %w[unset pending approved rejected].freeze

  private

    # 「変更」にチェックが入っていて、かつ選択肢に無いステータスを弾いた行だけを返す
    def submitted_changes(param_key)
      submitted = params.fetch(param_key, {})

      submitted.to_unsafe_h.select do |_id, attributes|
        attributes["apply"] == "1" && SELECTABLE_STATUSES.include?(attributes["status"])
      end
    end

    def apply_status_changes(scope, changes)
      target_records = scope.awaiting_decision.where(id: changes.keys)
      failed_count = 0

      target_records.each do |record|
        record.update!(status: changes[record.id.to_s]["status"])
      rescue ActiveRecord::RecordInvalid, ActiveRecord::LockWaitTimeout, ActiveRecord::Deadlocked
        failed_count += 1
      end

      failed_count
    end

    # 自分宛ての、まだ結論が出ていない申請を、申請者ごとにグループ化して返す
    def group_pending_by_applicant(scope, includes:, order:, joins: nil)
      relation = scope.awaiting_decision.includes(*includes)
      relation = relation.joins(joins) if joins
      relation.order(order).group_by(&:user)
    end
end
