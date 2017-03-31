## Social Bike

[![Platform](https://img.shields.io/badge/platform-ios-blue.svg?style=flat
)](https://developer.apple.com/iphone/index.action)
[![ObjectiveC](https://img.shields.io/badge/Objective--C-2.0-blue.svg)](https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/Introduction/Introduction.html)

This is a native iOS social-network app, with realtime chats.

<p align="center">
<img src="https://preview.ibb.co/daA1Tv/Simulator_Screen_Shot_Mar_31_2017_4_19_13_PM.png" width="250" border="10">
<img src="https://preview.ibb.co/nJQwva/Simulator_Screen_Shot_Mar_31_2017_4_18_33_PM.png" width="250" border="10">
</br>
<img src="https://preview.ibb.co/mpsn1F/Simulator_Screen_Shot_Mar_31_2017_4_54_22_PM.png" width="250" border="10">
<img src="https://preview.ibb.co/duNLMF/Simulator_Screen_Shot_Mar_31_2017_4_18_51_PM.png" width="250" border="10">
</br>
<img src="https://preview.ibb.co/eaaqMF/Simulator_Screen_Shot_Mar_31_2017_4_19_00_PM.png" width="250" border="10">
<img src="https://preview.ibb.co/geoYaa/Simulator_Screen_Shot_Mar_31_2017_4_19_05_PM.png" width="250" border="10">
</br>
<img src="https://preview.ibb.co/c3Xtaa/Simulator_Screen_Shot_Mar_31_2017_4_19_09_PM.png" width="250" border="10">
</p>

## FEATURES

- Using FireBase and Cloundinary services
- Login with VK ,FB or G+ ,or create new account
- Detail profile editing ,or deleting account
- Real time conversations with other users
- Send text/photo messages
- Group and privat chats
- Create your own Group chats 
- Detail chat editing
- Online status
- Nice and minimalistic design
- Support all IOS devices

---
## USING LIBS

- TOCropViewController
- Google/SignIn
- Firebase lib
- VK-ios-sdk
- JSQMessagesViewController
- TOCropViewController
- SVPullToRefresh
- JSONModel
- Rechability
- SWRevealViewController

## INSTALLATION

**1.** Install pod files , using 'pod install' in terminal

**2.** Your Xcode project should contain `GoogleService-Info.plist`, downloaded from [Firebase console](https://console.firebase.google.com) when you add your app to a Firebase project.<br>
Copy `GoogleService-Info.plist` into sample the project folder (`samples/obj-c/GoogleService-Info.plist` or `samples/swift/GoogleService-Info.plist`).

**3.** Update `Info.plist` vk ,facebook and cloudinary configuration values
  + `FacebookAppID -> {your-app-id}` (put Facebook App Id)
  + `FacebookDisplayName -> {your-app-display-name}` (put Facebook App display name)
  + `VKAppID -> {your-app-id}` (put VK App Id)
  OPTIONAL (IF U WANT TO USE IMAGES)
  + `CloudinaryName -> {storage-name}` (put Cloudinary storage name)
  + `CloudinarySecretKey -> {secret-key}}` (put Cloudinary secret key)
  + `CloudinaryApiKey -> {api-key}` (put Cloudinary api key)

**4.** Update URL Types.<br>
Go to `Project Settings -> Info tab -> Url Types` and update values for:
	+ `REVERSED_CLIENT_ID` (get value from `GoogleService-Info.plist`)
	+ `fb{your-app-id}` (put Facebook App Id)
	+ `vk{your-app-id}` (put VK App Id)

## LICENSE

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
