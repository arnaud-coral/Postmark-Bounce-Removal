# 📧 Postmark Bounce Removal Script

This script interacts with the Postmark API to remove bounces based on the domain and bounce type provided.

## 🛠️ Setup

1. Clone this repository or download the script.
2. Store your API token in a file named `api_token.conf`.

## 🌟 Features
- **Domain Filtering**: Target specific domains for bounce removal.
- **Bounce Type Selection**: Choose the types of bounces you wish to process, or opt to handle all bounce types.
- **Dry-Run Mode**: Safely preview which records would be removed without actually making deletions.
- **Debug Mode**: Detailed logging to troubleshoot or understand the script's operations.
- **Result Output**: Generates a CSV (`result.csv`) containing the results of the operation with each email's `DeletionStatus`.

## 🚀 Usage
Execute the script with various parameters to customize its behavior:

```
./script_name.sh --domains=example.com,example2.com
./script_name.sh --file=domains.conf
./script_name.sh --domains=example.com --dry-run
./script_name.sh --debug
```

## 📝 Parameters

- `--domains=`: Comma-separated list of domains to process. You can even use 'all' to process all domains.
- `--file=`: Alternatively, provide a file named `domains.conf` with one domain listed on each line.
- `--dry-run`: Simulate the bounce removal process without performing any real deletions.
- `--debug`: Runs the script in debug mode, outputting detailed logs.

## 🔢 Bounce Types

You'll be prompted to select a bounce type from the following list:
1. AddressChange
2. AutoResponder
3. BadEmailAddress
4. Blocked
5. ChallengeVerification
6. DMARCPolicy
7. DnsError
8. HardBounce
9. InboundError
10. ManuallyDeactivated
11. OpenRelayTest
12. SMTPApiError
13. SoftBounce
14. SpamComplaint
15. SpamNotification
16. Subscribe
17. TemplateRenderingFailed
18. Transient
19. Undeliverable
20. Unconfirmed
21. Unsubscribe
22. Unknown
23. VirusNotification
24. All

## ⚠️ Caution
Always use the `--dry-run` option first to ensure the script behaves as expected. The deletion of bounces is irreversible.

## 📜 License
Postmark Bounce Removal Script © 2023 by Arnaud Coral is licensed under [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/)
