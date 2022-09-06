import requests
import json
from typing import Dict, Any
requests.packages.urllib3.disable_warnings(requests.packages.urllib3.exceptions.InsecureRequestWarning)


class ApicDevice:
    def __init__(self, apic_hostname: str, apic_user: str, apic_password: str, ssl_verification: bool=True) -> None:
        self.apic_hostname = apic_hostname
        self.apic_user = apic_user
        self.apic_password = apic_password
        self.ssl_verification = ssl_verification
        self.auth_cockie = {'APIC-cookie': None}

    def apic_auth(self) -> None:
        auth = requests.post(url=f'{self.apic_hostname}/api/aaaLogin.json',
                        json={
                            "aaaUser": {
                                "attributes": {
                                    "name": self.apic_user,
                                    "pwd": self.apic_password
                                }
                            }
                        },
                        verify=self.ssl_verification).json()
        token = auth["imdata"][0]["aaaLogin"]["attributes"]["token"]
        self.auth_cockie['APIC-cookie'] = token
    
    def custom_api_get_request(self, custom_url: str) -> Dict[Any, Any]:
        r = requests.get(url=f'{self.apic_hostname}{custom_url}',
                         cookies=self.auth_cockie,
                         verify=self.ssl_verification)
        return r.json()


APIC_URL = 'https://apic.example.com'
APIC_USER = 'admin'
APIC_PASS = 'admin'
CUSTOM_URL = '/api/node/class/fabricNode.json'


if __name__ == "__main__":
    apic = ApicDevice(APIC_URL, APIC_USER, APIC_PASS, False)
    apic.apic_auth()
    response = apic.custom_api_get_request(CUSTOM_URL)
    print(json.dumps(response, indent=4, sort_keys=True))
