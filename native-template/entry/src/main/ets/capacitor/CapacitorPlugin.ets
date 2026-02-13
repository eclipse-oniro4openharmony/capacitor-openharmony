import { common } from '@kit.AbilityKit';
import { CapacitorBridge } from './CapacitorBridge';

export abstract class CapacitorPlugin {
  protected bridge: CapacitorBridge;
  protected context: common.UIAbilityContext;

  constructor(bridge: CapacitorBridge, context: common.UIAbilityContext) {
    this.bridge = bridge;
    this.context = context;
  }

  load(): void {}

  notifyListeners(eventName: string, data: Object): void {
    this.bridge.notifyListeners(this.getPluginId(), eventName, data);
  }

  abstract getPluginId(): string;
}
