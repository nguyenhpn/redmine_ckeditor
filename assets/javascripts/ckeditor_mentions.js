const clickUserMentions = () => {
    const enableUserMentions = document.getElementById('settings_user_mentions');
    const divUserMentions = document.querySelector('div.user_mentions_options_box');

    if (enableUserMentions.checked) {
        divUserMentions.classList.remove('hidden');
    } else {
        divUserMentions.classList.add('hidden');
    }
}

const clickIssueMentions = () => {
    const enableIssueMentions = document.getElementById('settings_issue_mentions');
    const divIssueMentions = document.querySelector('div.issue_mentions_options_box');

    if (enableIssueMentions.checked) {
        divIssueMentions.classList.remove('hidden');
    } else {
        divIssueMentions.classList.add('hidden');
    }
}

const clickUserMentionsNotifications = () => {
    const enableUserNotifications = document.getElementById('settings_user_mentions_notifications');
    const userNotificationBox = document.querySelector('div.user_notifications_box');

    if (enableUserNotifications.checked) {
        userNotificationBox.classList.remove('hidden');
    } else {
        userNotificationBox.classList.add('hidden');
    }
}

const clickIssueMentionsNotifications = () => {
    const enableIssueNotifications = document.getElementById('settings_issue_mentions_notifications');
    const issueNotificationBox = document.querySelector('div.issue_notifications_box');

    if (enableIssueNotifications.checked) {
        issueNotificationBox.classList.remove('hidden');
    } else {
        issueNotificationBox.classList.add('hidden');
    }
}

document.addEventListener('DOMContentLoaded', () => {
    clickUserMentions();
    clickIssueMentions();
    clickUserMentionsNotifications();
    clickIssueMentionsNotifications();
})
