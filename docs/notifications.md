# Notifications via MS Teams

> Instruction to configure notifications via MS Teams

<hr>

- [1. MS Teams](#1-ms-teams)
  - [1.1 Team creation](#11-team-creation)
  - [1.2 Team configuration](#12-team-configuration)
  - [1.3 Channel creation](#13-channel-creation)
  - [1.4 Channel configuration](#14-channel-configuration)
- [2. Gitea](#2-gitea)
  - [2.1 Webhook configuration](#21-webhook-configuration)

<br>

## 1. MS Teams

Guide to create and configure team in Microsoft Teams.

### 1.1 Team creation

Steps to create a team:

1. Login to your Microsoft Teams account.
2. Switch to Teams view.
3. Click on `Join or create a team`.
4. Select `Create a team` and click on `Create team` button.
5. Select `From scratch`.
6. In `What kind of team will this be?` select `Private`.
7. Enter a name for your team and click on `Create` button.
8. Skip any additional steps.

### 1.2 Team configuration

Steps to add Connector to team:

1. In the main team page, click on `three dots` (More options) next to the `Meet` button.
2. In dropdown menu, select `Connectors`.
3. In the list of available connectors, select `Incoming Webhook` and click on `Add`.
4. In dialog, click on `Add` button.

### 1.3 Channel creation

Steps to create more channels:

1. Click on `three dots` (More options) next to the team name.
2. In the dropdown menu, select `Add channel`.
3. In the `Create a channel` dialog:
    - Enter a name for your channel.
    - Select `Private` or `Public`.
    - Click on `Create` button.

### 1.4 Channel configuration

Steps to configure Connectors in Microsoft Teams:

> :exclamation: You can reproduce this process for each channel.

1. Click on `three dots` (More options) next to the channel name.
2. In the dropdown menu, select `Connectors`.
3. Next to `Incoming Webhook` click on `Configure`.
4. In `Connectors for ...` dialog:
   - Enter name of Connector that will post to this channel. Example: `Gitea Bot`.
   - Click on `Create` button.
5. Copy the URL below and save it to later use (channel webhook URL).
6. Click on `Done` button.

<br>

## 2. Gitea

Guide to configure system webhook in Gitea.

### 2.1 Webhook configuration

Steps to configure webhook:

1. Login to Gitea as administrator.
2. Click on `Profile and settings` menu next to profile icon.
3. In dropdown menu, select `Site administration`.
4. Navigate to `Webhooks`.
5. In `System Webhooks` section, click on `Add Webhook` button and select `Microsoft Teams`.
6. In the `Add System Webhook` page:
   - `Target URL`: channel webhook URL.
   - `Trigger On:` select `All events`.
   - `Branch filter`: leave `*` - notify about all branches or enter specific branch name.
   - Click on `Add Webhook` button.
