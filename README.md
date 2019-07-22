# Amplify SwiftUI Demo

Get started using Amplify and SwiftUI

## Getting Started - Clone the repo

First we will be getting started with the master branch so go head and clone it into a working directory.

### Configuring the iOS applicaion - AppSync iOS Client SDK

Install the AppSync iOS SDK by running:
```js
pod install --repo-update
```

### Install and Configure the Amplify CLI - Just Once

Next, we'll install the AWS Amplify CLI:

```bash
npm install -g @aws-amplify/cli
```

After installation, configure the CLI with your developer credentials:

Note: If you already have the AWS CLI installed and use a named profile, you can skip the `amplify configure` step.
`Amplify configure` is going to have you launch the AWS Management Console, create a new IAM User, asign an IAM Policy, and collect the programmatic credentials to craate a CLI profile that will be used to provision AWS resources for each project in future steps.

```js
amplify configure
```

> If you'd like to see a video walkthrough of this configuration process, click [here](https://www.youtube.com/watch?v=fWbM5DLh25U).

Here we'll walk through the `amplify configure` setup. Once you've signed in to the AWS console, continue:
- Specify the AWS Region: __us-east-1__
- Specify the username of the new IAM user: __amplify-workshop-user__
> In the AWS Console, click __Next: Permissions__, __Next: Tags__, __Next: Review__, & __Create User__ to create the new IAM user. Then, return to the command line & press Enter.
- Enter the access key of the newly created user:   
? accessKeyId: __(<YOUR_ACCESS_KEY_ID>)__   
? secretAccessKey:  __(<YOUR_SECRET_ACCESS_KEY>)__
- Profile Name: __amplify-workshop-user__

### Initializing A New Amplify Project
From the root of your Xcode project folder:
```bash
amplify init
```

- Enter a name for the project: __iosamplifyapp__
- Enter a name for the environment: __master__
- Choose your default editor: __Visual Studio Code (or your default editor)__   
- Please choose the type of app that you're building __ios__     
- Do you want to use an AWS profile? __Y__
- Please choose the profile you want to use: __amplify-workshop-user__

AWS Amplify CLI will iniatilize a new project & you'll see a new folder: __amplify__ & a new file called `awsconfiguration.json` in the root directory. These files hold your Amplify project configuration.

To view the status of the amplify project at any time, you can run the Amplify `status` command:

```sh
amplify status
```

## Adding a GraphQL API
In this section we'll add a new GraphQL API via AWS AppSync to our iOS project backend. 
To add a GraphQL API, we can use the following command:

```sh
amplify add api
```

Answer the following questions:

- Please select from one of the above mentioned services __GraphQL__   
- Provide API name: __ConferenceAPI__   
- Choose an authorization type for the API __API key__   
- Do you have an annotated GraphQL schema? __N__   
- Do you want a guided schema creation? __Y__   
- What best describes your project: __Single object with fields (e.g. “Todo” with ID, name, description)__   
- Do you want to edit the schema now? (Y/n) __Y__   

When prompted and the default schema launches in your favorite editor, update the default schema to the following:   

```graphql
type Talk @model {
  id: ID!
  clientId: ID
  name: String!
  description: String!
  speakerName: String!
  speakerBio: String!
}
```

Next, let's deploy the GraphQL API into our account:
This step take the local CloudFormation templates and deployes them to the AWS Cloud for provisioning of the services you enabled via the `add API` category.
```bash
amplify push
```

- Do you want to generate code for your newly created GraphQL API __Y__
- Enter the file name pattern of graphql queries, mutations and subscriptions: __(graphql/**/*.graphql)__
- Do you want to generate/update all possible GraphQL operations - queries, mutations and subscriptions? __Y__
- Enter maximum statement depth [increase from default if your schema is deeply nested] __2__
- Enter the file name for the generated code __API.swift__

> To view the new AWS AppSync API at any time after its creation, go to the dashboard at [https://console.aws.amazon.com/appsync](https://console.aws.amazon.com/appsync). Also be sure that your region is set correctly.

## Add the `awsconfiguration.json` and `API.swift` files to your Xcode project

We need to configure our iOS Swift application to be aware of our new AWS Amplify project. We do this by referencing the auto-generated `awsconfiguration.json` and `API.Swift` files in the root of your Xcode project folder.

Launch Xcode using the .xcworkspace from now on as we are using Cocoapods.
```bash
$ open twitchConferences.xcworkspace/
```

In Xcode, right-click on the project folder and choose `"Add Files to ..."` and add the `awsconfiguration.json` and the `API.Swift` files to your project. When the Options dialog box that appears, do the following:

* Clear the Copy items if needed check box.
* Choose Create groups, and then choose Next.

Build the project (Command-B) to make sure we don't have any compile errors.

## Initialize the AppSync Store and drawing the list view

### AppDelegate.swift

Add these lines to your AppDelegate file, to configure your AppSync Client.

```swift
@import UIKit
@import AWSAppSync
...
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    public var appSyncClient: AWSAppSyncClient!
...

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        do {
            let appSyncConfig = try AWSAppSyncClientConfiguration(appSyncServiceConfig: AWSAppSyncServiceConfig(),cacheConfiguration: AWSAppSyncCacheConfiguration())
            
            appSyncClient = try AWSAppSyncClient(appSyncConfig: appSyncConfig)
            
            // Initialize the AWS AppSync client
            
        } catch {
            print("Error initializing AppSync client. \(error)")
            appSyncClient = nil
        }
        return true
    }
```

### TalkStore.swift

Now that we have a configure AppSync Client we need to configure our TalkStore. This TalkStore contains the data that our views will be referencing throughout our design. With the release of the new SwiftUI and Combine framework they introducted a few new object types. The one we are going to be using today for our store is a `BindableObject`.

To get started with `TalkStore` first make the it inherit the `BindableObject` class and also add AWSAppSync to our imports.
```swift
import AWSAppSync

final class TalkStore: BindableObject {
```

Now to make it adhere to the `BindableObject` class we need to add a PublisherType so whenever anything changes we will publish to a topic notifying the view that things have changed and it should redraw. For those that are familiar with React this is similiar to how props work.

```swift
/*
    Required by SwiftUI
*/
let didChange = PassthroughSubject<TalkStore, Never>()
var listTalks: [ListTalksQuery.Data.ListTalk.Item] {
    didSet {
        didChange.send(self)
    }
    
}

//We will be using this later.
private let appSyncClient: AWSAppSyncClient!
```

Now lets create the init. We will need to set the initial value for the list of talks and also setup the AppSync Client for this store to be using the client we configure earlier in the AppDelegate.

```swift
init(){
    self.listTalks = []
    appSyncClient = (UIApplication.shared.delegate as! AppDelegate).appSyncClient
        
        // Initialize the AWS AppSync client
    appSyncClient.fetch(query: ListTalksQuery(), cachePolicy: .returnCacheDataAndFetch) { (result, error) in
        if (error != nil){
            print(error?.localizedDescription ?? "")
            return
        } else {
            guard let talks = result?.data?.listTalks?.items else { return }
            self.listTalks = talks as! [ListTalksQuery.Data.ListTalk.Item]
        }
    }
}
```

That is all we need to do right now in this file. We will be coming back soon to add some unit tests for the UIView but for now we will move on.


### ContentView.swift

Click resume on the top of the Canvas on the right to make sure the project is not seeing any errors before diving in.

First lets add some fields that should show in the list view by using the default view. This can be formatted anyway but should contain a place for the `name` and the `speakerName` to a cell. Here is an example:

```swift
struct ContentView : View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("name")
                .font(.title)
            Text("speakerName")
                .font(.subheadline)
        }
    }
}
```

Now that the cell has been defined, the next step is defining the list. First it is important to bring in the store needed to populate the `Table`. In your `ContentView` add in a `@State var` for the store. Something like this:
```swift
struct ContentView : View {
    @EnvironmentObject var talkStore : TalkStore

    ...

}
```

You will now notice that we have errors if you try to run the app or use the resume button. This is because the enviroment object we just added needs to be initalized for both the testing and the production level builds. 

To add the production fix:
Navigate to `SceneDelgate.swift` and find this line:
```swift
window.rootViewController = UIHostingController(rootView: ContentView())
```

`ContentView` will need an `environmentObject` to be able to function correctly.

To add an `enviromentOjbect` to `ContentView` replace this line with this.

```swift
window.rootViewController = UIHostingController(rootView: ContentView().environmentObject(TalkStore()))
```

To add the test fix: 

Navigate back to the `TalkStore.swift` and add in this new `init()` for testing:
```swift
/*
Init if running app is using SwiftUI Content View
*/
init(talks: [ListTalksQuery.Data.ListTalk.Item]){
    self.appSyncClient = nil
    self.listTalks = talks
}
```
Now to get our resume fixed we need to add some test data in for our init:
Go back to the `ContentView.swift` and scroll down to the `#if DEBUG` and add some test data like so:
```swift
#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        let sampleData = [
            ListTalksQuery.Data.ListTalk.Item(id: "0", name: "SwiftUI and Amplify", description: "", speakerName: "Sam Patzer", speakerBio: ""),
            ListTalksQuery.Data.ListTalk.Item(id: "1", name: "WWDC Recap", description: "", speakerName: "Tim Apple", speakerBio: ""),
            ListTalksQuery.Data.ListTalk.Item(id: "2", name: "Bash Party", description: "", speakerName: "Weezer", speakerBio: "")
        ]
        return ContentView()
        .environmentObject(TalkStore(talks: sampleData))
    }
}
#endif
```

Now we have some canvas data available so we want to build a list view that actually shows that data instead of the name and speaker place holders.

Lets first add our data to our `VStack` through List like so:
```swift
var body: some View {
    List(talkStore.listTalks.identified(by:\.id)){ talk in
        VStack(alignment: .leading) {
            ... 
        }
    }
    .listStyle(.grouped)
}
```
It is important to note the `.identified(by: )` section. SwiftUI requires each row to have a unique id associated with it.

Now to actually get the data out of the talk variable you just need to reference it like any other string in swift:
```swift
"\(talk.name)
```

Now we have successfully created a list view using SwiftUI and AppSync. Up next we need to add data to our table!

## Adding data to the table and creating talks

### TalkStore.swift

First to add talks we need to add the ability to add talks to through our Store which communicates with our AppSync endpoint.

```swift
func add(create: CreateTalkInput){
    if (appSyncClient != nil){
        print("Appsync not null")
        appSyncClient?.perform(mutation: CreateTalkMutation(input: create))
        { (result, error) in
            print("Calling")
            if let error = error as? AWSAppSyncClientError {
                print("Error occurred: \(error.localizedDescription )")
                return
            }
            if let resultError = result?.errors {
                print("Error saving conf talk: \(resultError)")
                return
            }
            
            guard let result = result?.data else { return }
            self.listTalks.append(self.mapAdd(neededConversion: result.createTalk!))
            print("Talk created: \(String(describing: result.createTalk?.id))")
        }
        //write it to our backend
    } else {
        listTalks.append(mapAdd(neededConversion: CreateTalkMutation.Data.CreateTalk(id: "0", name: create.name, description: create.description, speakerName: create.speakerName, speakerBio: create.speakerBio)))
    }
}

private func mapAdd(neededConversion:
    CreateTalkMutation.Data.CreateTalk) -> ListTalksQuery.Data.ListTalk.Item{
    let newItem = ListTalksQuery.Data.ListTalk.Item(id: neededConversion.id, clientId: neededConversion.clientId, name: neededConversion.name, description: neededConversion.description, speakerName: neededConversion.speakerName, speakerBio: neededConversion.speakerBio)
    return newItem
}
```

You will notice that if the appSyncClient is nil then we will just append it to the array and move on. This is for testing purposes only.

### AddTalkView.swift

Now we need to crate our form for creating our talks!

First lets create our Form:

```swift

enum StateOfCreation {
    case save
    case dismiss
    case hide
    case show
}

struct AddTalk : View {
    @Binding var talk : CreateTalkInput
    @Binding var isShowing : StateOfCreation
    @EnvironmentObject var talkStore : TalkStore
    
    var body: some View {
        NavigationView{
            Form{
                Section(header:Text("Talk Name")){
                    TextField($talk.name)
                    .lineLimit(1)
                }
                Section(header:Text("Talk Description")){
                        TextField($talk.description)
                        .frame(height:150)
                }
                Section(header:Text("Speaker Name")){
                    TextField($talk.speakerName)
                    .lineLimit(1)
                }
                Section(header:Text("Speaker Bio")){
                    TextField($talk.speakerBio)
                        .frame(height:150)
                }
            }
        .listStyle(.grouped)
        .navigationBarTitle(Text("Add Talk"))
        .navigationBarItems(trailing:
            Button(action: {
                    if (self.talk.name == "" || self.talk.speakerName == ""){
                        
                    } else {
                        self.isShowing = .save
                        self.talkStore.add(create:self.talk)
                    }
                
                }, label: {
                    Text("Save")
            }))
        }
    }
}
```

To view what this looks like in the live view we need to modify the test like below:

```swift
#if DEBUG
struct AddTalk_Previews : PreviewProvider {
    static var previews: some View {
        return AddTalk(talk: .constant(.init(name: "", description: "", speakerName: "", speakerBio: "")), isShowing: .constant(.show))
    }
}
#endif
```

### ContentView.swift

Now that we have a great looking Form we need to add the ability to actually see this form from our list!

Surround the `List{}` with a ``NavigationView` and add in two new state variables that will help us keep track of if we are displaying the form and what the value of the talk is. It should look something like this:
```swift
struct ContentView : View {
    @EnvironmentObject var talkStore : TalkStore
    @State var shouldCreate : StateOfCreation = .hide
    @State var newTalk : CreateTalkInput = CreateTalkInput(name: "", description: "", speakerName: "", speakerBio: "")
    var body: some View {
        NavigationView {
            List {
                ...
            }
        }
    }
}

```

Now we can navigate since we added a NavigationView! Now we just need add a function that will actually present the view.

After the `.listStyle` we will be adding some Navigation Bar items. This first item will be a title and the second is a plus button to show our form we made!

```swift
.listStyle(.grouped)
.navigationBarTitle(Text("Talks"))
.navigationBarItems(trailing: Button(action: {
        self.shouldCreate = .show
    }, label: {
        Image(systemName: "plus").font(.title)
    }).disabled(self.shouldCreate == .show))
    .presentation(self.shouldCreate == .show ? Modal(AddTalk(talk: $newTalk, isShowing:$shouldCreate).environmentObject(talkStore), onDismiss: {
        self.shouldCreate = .hide
        self.newTalk =  CreateTalkInput(name: "", description: "", speakerName: "", speakerBio: "")
}) : nil)
```

And there we go! Now we can add talks to our list of talks.

## License Summary

This sample code is made available under the MIT-0 license. See the LICENSE file.
