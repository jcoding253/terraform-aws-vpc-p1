References

https://docs.aws.amazon.com/cli/latest/userguide/sso-configure-profile-token.html

https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html

https://www.youtube.com/watch?v=CfA-pOQK8Fg

While logged into an AWS user account. Set up the SSO by creating these things: group, user, custom url and an association to permissions.

    Go to IAM Identity Center
    Go to “settings”, click “change identity source” right side, to change “access URL”.
    ex: [https://business1.awsapps.com/start]
    Create group, ex: [adminaccess]
    Create user, ex: [username1], assign to group
    Go to “AWS Accounts”, select account, ex: the management account
        Assign group to the account
    This would be for full admin access. You could associate to any accounts, users or groups.

Terminal, create configuration sessions and profiles for sso on local machine, commands:

    $ aws configure sso
    $ [insert session name ex: username1]
    $ [insert the access url ex: https://business1.awsapps.com/start]
    $ us-east-1
    $ sso:account:access
    $ us-east-1
    $ json
    $ [insert profile name ex: admin1]
    $ export AWS_PROFILE=[admin1]

Terraform should now be able to use AWS CLI automatically. Here are some extras:

    Terminal cmd to log back in when session expires:
        $ export AWS_PROFILE=[insert profile ex:admin1]
        $ aws sso login --profile [insert profile ex:admin1]
    Terminal cmd to edit one of the config settings
        $ aws configure set [selected setting here] [text to insert] --profile [name]
        Ex: $ aws configure set region us-east-1 --profile admin1
        Ex: $ aws configure set CLI_default_output_format json --profile admin1

Alternatively, you can globally configure the environment variables, but I prefer the temporary session offered from SSO. 

    Log into your AWS user and generate an access key pair.
    Copy them in the terminal commands below:
        $ export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
        $ export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
        $ export AWS_DEFAULT_REGION=us-east-1
