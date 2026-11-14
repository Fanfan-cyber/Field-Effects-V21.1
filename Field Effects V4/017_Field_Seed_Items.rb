class Battle
  def pbCheckFieldSeedActivation(battler)
    return if !battler || battler.fainted?
    return unless has_field?
    field = current_field
    seed_type = field.seed_type
    return unless seed_type
    return unless battler.item == seed_type
    return unless battler.itemActive?

    stats = field.seed_stats || {}
    has_stat_data = !stats.empty?
    has_effect_data = !field.seed_effect.nil?
    return unless has_stat_data || has_effect_data

    if has_stat_data && !has_effect_data
      can_boost = stats.keys.any? { |stat| battler.pbCanRaiseStatStage?(stat, battler) }
      return unless can_boost
    end

    pbCommonAnimation("UseItem", battler)
    apply_field_effect(:on_seed_use, battler, seed_type)
    battler.pbConsumeItem
  end

  alias seed_items_apply_field_effect apply_field_effect unless method_defined?(:seed_items_apply_field_effect)
  def apply_field_effect(effect_name, *args)
    result = seed_items_apply_field_effect(effect_name, *args)
    pbCheckFieldSeedActivation(args[0]) if [:set_field_battler, :switch_in].include?(effect_name)
    result
  end

  alias seed_items_pbBattleLoop pbBattleLoop unless method_defined?(:seed_items_pbBattleLoop)
  def pbBattleLoop
    unless @seed_items_start_checked
      @seed_items_start_checked = true
      eachBattler { |battler| pbCheckFieldSeedActivation(battler) }
    end
    seed_items_pbBattleLoop
  end
end

class Battle
  def dam_electric_seed(battler)
    return if !battler || battler.fainted?
    return unless battler.item == :ELECTRICSEED
    return unless battler.itemActive?
    return unless battler.pbCanRaiseStatStage?(:DEFENSE, battler)
    pbCommonAnimation("UseItem", battler)
    battler.pbRaiseStatStageByCause(:DEFENSE, 1, battler, battler.itemName)
    battler.pbConsumeItem
  end
end

module DamFieldSeedHooks
  def pbCheckFieldSeedActivation(battler)
    dam_electric_seed(battler) if dam_field?
    super
  end
end
Battle.prepend(DamFieldSeedHooks)
