import { Component, OnInit } from '@angular/core';
import { Device } from '@capacitor/device';
import { Network } from '@capacitor/network';

@Component({
  selector: 'app-tab1',
  templateUrl: 'tab1.page.html',
  styleUrls: ['tab1.page.scss'],
  standalone: false,
})
export class Tab1Page implements OnInit {
  deviceInfo: any;
  networkStatus: any;

  constructor() {}

  async ngOnInit() {
    try {
      this.deviceInfo = await Device.getInfo();
      this.networkStatus = await Network.getStatus();
    } catch (e) {
      console.error('Error fetching info', e);
    }
  }
}
