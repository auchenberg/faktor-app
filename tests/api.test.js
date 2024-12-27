const fetch = require('node-fetch');

describe('Faktor API Tests', () => {
    const API_URL = 'https://getfaktor.com/api/extract-code';
    const TIMEOUT = 10000; // 10 seconds

    describe('English Messages', () => {
        const englishCases = [
            // Basic format variations
            {
                message: "123-456 is your Resy account verification code.",
                expected: { service: "Resy", code: "123-456" }
            },
            {
                message: "G-412157 is your Google verification code.",
                expected: { service: "Google", code: "G-412157" }
            },
            {
                message: "469538 is your verification code for your Sony Entertainment Network account.",
                expected: { service: "Sony Entertainment Network", code: "469538" }
            },
            {
                message: "512665 (NetEase Verification Code)",
                expected: { service: "NetEase", code: "512665" }
            },

            // Square bracket format
            {
                message: "[Alibaba Group]Your verification code is 797428",
                expected: { service: "Alibaba Group", code: "797428" }
            },
            {
                message: "[HuomaoTV]code: 456291. Please complete the verification within 5 minutes.",
                expected: { service: "HuomaoTV", code: "456291" }
            },
            {
                message: "[zcool]Your verification code is 991533",
                expected: { service: "zcool", code: "991533" }
            },
            {
                message: "[SwiftCall]Your verification code: 6049",
                expected: { service: "SwiftCall", code: "6049" }
            },
            {
                message: "[EggOne]Your verification code is: 562961, valid for 10 minutes.",
                expected: { service: "EggOne", code: "562961" }
            },

            // Service-specific formats with URLs or special formatting
            {
                message: "Your WhatsApp code is 105-876 but you can simply tap on this link to verify your device: v.whatsapp.com/105876",
                expected: { service: "WhatsApp", code: "105-876" }
            },
            {
                message: "WhatsApp code 507-240",
                expected: { service: "WhatsApp", code: "507-240" }
            },
            {
                message: "Your LinkedIn verification code is 804706.",
                expected: { service: "LinkedIn", code: "804706" }
            },
            {
                message: "Your Google verification code is 596465",
                expected: { service: "Google", code: "596465" }
            },
            {
                message: "Your Twitter confirmation code is 180298",
                expected: { service: "Twitter", code: "180298" }
            },
            {
                message: "Use 003407 as your password for Facebook for iPhone.",
                expected: { service: "Facebook", code: "003407" }
            },

            // Simple formats
            {
                message: "2715",
                expected: { service: "Unknown", code: "2715" }
            },
            {
                message: "VerifyCode:736136",
                expected: { service: "Unknown", code: "736136" }
            },

            // Messages with security warnings
            {
                message: "Your Intuit Code is 097074. Do not share this code. We'll never call or text you for it.",
                expected: { service: "Intuit", code: "097074" }
            },
            {
                message: "Snapchat code: 481489. Do not share it or use it elsewhere!",
                expected: { service: "Snapchat", code: "481489" }
            },
            {
                message: "This is your secret password for REGISTRATION. GO-JEK never asks for your password, DO NOT GIVE IT TO ANYONE. Your PASSWORD is 1099.",
                expected: { service: "GO-JEK", code: "1099" }
            },

            // Various service formats
            {
                message: "Your one-time eBay pin is 3190",
                expected: { service: "eBay", code: "3190" }
            },
            {
                message: "Telegram code 65847",
                expected: { service: "Telegram", code: "65847" }
            },
            {
                message: "858365 is your 98point6 security code.",
                expected: { service: "98point6", code: "858365" }
            },
            {
                message: "0013 is your verification code for HQ Trivia",
                expected: { service: "HQ Trivia", code: "0013" }
            },
            {
                message: "750963 is your Google Voice verification code",
                expected: { service: "Google Voice", code: "750963" }
            },
            {
                message: "128931 is your BIGO LIVE verification code",
                expected: { service: "BIGO LIVE", code: "128931" }
            },
            {
                message: "Humaniq code: 167-262",
                expected: { service: "Humaniq", code: "167-262" }
            },
            {
                message: "Your Lyft code is 744444",
                expected: { service: "Lyft", code: "744444" }
            },
            {
                message: "Your Proton verification code is: 861880",
                expected: { service: "Proton", code: "861880" }
            },
            {
                message: "Your CloudSigma verification code for MEL is 880936",
                expected: { service: "CloudSigma", code: "880936" }
            },
            {
                message: "Your Twilio verification code is: 9508",
                expected: { service: "Twilio", code: "9508" }
            },
            {
                message: "6635 is your Postmates verification code.",
                expected: { service: "Postmates", code: "6635" }
            },
            {
                message: "Microsoft access code: 6907",
                expected: { service: "Microsoft", code: "6907" }
            },
            {
                message: "Hi Kenneth, your Lemonade one-time passcode is 764631",
                expected: { service: "Lemonade", code: "764631" }
            },
            {
                message: "Your ExampleApp code is: 123ABC78 FA+9qCX9VSu",
                expected: { service: "ExampleApp", code: "123ABC78" }
            },
            {
                message: "Welcome to ClickSend, for your first login you'll need the activation PIN: 464120",
                expected: { service: "ClickSend", code: "464120" }
            },
            {
                message: "Here is your ofo verification code: 2226",
                expected: { service: "ofo", code: "2226" }
            },
            {
                message: "[#] Your Uber code: 5934 qlRnn4A1sbt",
                expected: { service: "Uber", code: "5934" }
            },
            {
                message: "373473(Weibo login verification code) This code is for user authentication.",
                expected: { service: "Weibo", code: "373473" }
            },
            {
                message: "Use the code (7744) on WeChat to log in to your account. Don't forward the code!",
                expected: { service: "WeChat", code: "7744" }
            },
            {
                message: "Your confirmation code is 951417. Please enter it in the text field.",
                expected: { service: "Unknown", code: "951417" }
            },
            {
                message: "588107 is your LIKE verification code",
                expected: { service: "LIKE", code: "588107" }
            },
            {
                message: "Auth code: 2607 Please enter this code in your app.",
                expected: { service: "Unknown", code: "2607" }
            },
            {
                message: "Use 5677 as Microsoft account security code",
                expected: { service: "Microsoft", code: "5677" }
            },
            {
                message: "0013 is your verification code for HQ Trivia",
                expected: { service: "HQ Trivia", code: "0013" }
            }
        ];

        englishCases.forEach(runTest);
    });

    describe('International Messages', () => {
        const internationalCases = [
            // Czech
            {
                message: "J&T BANKA: Vas autentizacni kod pro prihlaseni do aplikace ePortal je: 7708-5790",
                expected: { service: "J&T BANKA", code: "7708-5790" }
            },
            {
                message: "Vas overovaci kod do SPARTA iD je RW9X0E.",
                expected: { service: "SPARTA iD", code: "RW9X0E" }
            },
            {
                message: "Prihlasovaci kod na portal http://moje.partners.cz: ragepr Platnost kodu: 10 minut",
                expected: { service: "Unknown", code: "ragepr" }
            },

            // Russian
            {
                message: "Пароль: 1752 (никому не говорите) Доступ к информации",
                expected: { service: "Unknown", code: "1752" }
            },

            // Spanish
            {
                message: "Su código de verificación para tu cuenta de Google es 1234567890.",
                expected: { service: "Google", code: "1234567890" }
            },

            // French
            {
                message: "Votre code de vérification pour votre compte Google est 1234567890.",
                expected: { service: "Google", code: "1234567890" }
            },

            // German
            {
                message: "Ihr Code für die Google-Konten-Verifizierung ist 1234567890.",
                expected: { service: "Google", code: "1234567890" }
            },
            {
                message: "117740 ist dein Verifizierungscode für dein Sony Entertainment Network-Konto.",
                expected: { service: "Sony Entertainment Network", code: "117740" }
            },

            // Italian
            {
                message: "Il codice di verifica per il tuo account Google è 1234567890.",
                expected: { service: "Google", code: "1234567890" }
            },

            // Korean
            {
                message: "G-723210(이)가 Google 인증 코드입니다.",
                expected: { service: "Google", code: "G-723210" }
            },

            // Japanese
            {
                message: "Cash Show - 賞金クイズ の確認コードは 764972 です。",
                expected: { service: "Cash Show", code: "764972" }
            },

            // Additional Vietnamese case
            {
                message: "(Zalo) 8568 la ma kich hoat cua so dien thoai 13658014095.",
                expected: { service: "Zalo", code: "8568" }
            },
            // Additional Chinese case
            {
                message: "You are editing the phone number information of your weibo account, the verification code is: 588397",
                expected: { service: "Weibo", code: "588397" }
            },
            // Danish
            {
                message: "Din verifikationskode til Google er 1234567890.",
                expected: { service: "Google", code: "1234567890" }
            }
        ];

        internationalCases.forEach(runTest);
    });

    describe('Special Cases', () => {
        const specialCases = [
            // Messages without codes
            {
                message: "Reasy. Set. Get. Your new glasses are ready for pick up at LensCrafters!",
                expected: { service: "LensCrafters", code: "null" }
            },

            // Phone numbers in messages
            {
                message: "388-941-4444 your code is 333222",
                expected: { service: "Unknown", code: "333222" }
            },
            {
                message: "+1-388-941-4444 your code is 333-222",
                expected: { service: "Unknown", code: "333-222" }
            },

            // Multi-line and multi-language messages
            {
                message: "46143020\nvalid 5 minutes\ndurata 5 minuti\ndurée 5 minutes\ngültig 5 minuten\r",
                expected: { service: "Unknown", code: "46143020" }
            },

            // Additional special cases
            {
                message: "someweird-pattern:a1b2c3",
                expected: { service: "Unknown", code: "a1b2c3" }
            }
        ];

        specialCases.forEach(runTest);
    });

    function runTest({ message, expected }) {
        test(`correctly parses: ${message.substring(0, 30)}...`, async () => {
            const response = await fetch(API_URL, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ message }),
            });

            expect(response.status).toBe(200);
            const result = await response.json();

            // Validate response structure
            expect(result).toHaveProperty('code');
            expect(result).toHaveProperty('service');

            if (expected.code === "null") {
                expect(result.code).toBeNull();
            } else {
                expect(result.code).toBe(expected.code);
            }

            // Compare service names case-insensitively
            expect(result.service).toBe(expected.service);
        }, TIMEOUT);
    }

    describe('Error Cases', () => {
        test('handles empty message', async () => {
            const response = await fetch(API_URL, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ message: '' }),
            });

            expect(response.status).toBe(400);
            const result = await response.json();
            expect(result.error).toBe("Message is required");
        });

        test('handles invalid JSON', async () => {
            const response = await fetch(API_URL, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: 'invalid json',
            });

            expect(response.status).toBe(500);
        });

        test('handles very long messages', async () => {
            const longMessage = 'A'.repeat(10000) + ' code: 123456';
            const response = await fetch(API_URL, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ message: longMessage }),
            });

            expect(response.status).toBe(200);
        });
    });
}); 