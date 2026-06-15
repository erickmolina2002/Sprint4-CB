const isOn = (v?: string): boolean => v === 'true' || v === '1';

export const vulnV1 = (): boolean => isOn(process.env.VULN_V1);
export const vulnV2 = (): boolean => isOn(process.env.VULN_V2);
export const vulnV3 = (): boolean => isOn(process.env.VULN_V3);
