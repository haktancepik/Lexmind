//
//  CommonWordsLibrary.swift
//  Lexmind
//
//  Curated set of frequently used English words with full analysis,
//  classified by CEFR level (A1–C2) and topic. Used as a built-in
//  starter deck that learners can import into their study queue.
//

import Foundation

struct LibraryRelation: Hashable {
    let term: String
    let verified: Bool
}

struct CommonWord: Identifiable, Hashable {
    let id = UUID()
    let term: String
    let partOfSpeech: String
    let ipa: String
    let countability: String
    let definition: String
    let turkishMeaning: String
    let examples: [String]
    let level: CEFRLevel
    let topics: [WordTopic]
    let familyRoot: String?
    let familyMembers: [String]
    let familyMembersVerified: [String]
    let inflectionExamples: [String]
    let synonyms: [LibraryRelation]
    let antonyms: [LibraryRelation]
    let related: [LibraryRelation]

    init(
        term: String,
        partOfSpeech: String,
        ipa: String,
        countability: String,
        definition: String,
        turkishMeaning: String,
        examples: [String],
        level: CEFRLevel,
        topics: [WordTopic],
        familyRoot: String? = nil,
        familyMembers: [String] = [],
        familyMembersVerified: [String] = [],
        inflectionExamples: [String] = [],
        synonyms: [LibraryRelation] = [],
        antonyms: [LibraryRelation] = [],
        related: [LibraryRelation] = []
    ) {
        self.term = term
        self.partOfSpeech = partOfSpeech
        self.ipa = ipa
        self.countability = countability
        self.definition = definition
        self.turkishMeaning = turkishMeaning
        self.examples = examples
        self.level = level
        self.topics = topics
        self.familyRoot = familyRoot
        self.familyMembers = familyMembers
        self.familyMembersVerified = familyMembersVerified
        self.inflectionExamples = inflectionExamples
        self.synonyms = synonyms
        self.antonyms = antonyms
        self.related = related
    }
}

enum CommonWordsLibrary {

    static func filtered(level: CEFRLevel? = nil, topic: WordTopic? = nil) -> [CommonWord] {
        all.filter { word in
            if let level, word.level != level { return false }
            if let topic, !word.topics.contains(topic) { return false }
            return true
        }
    }

    static let byTerm: [String: CommonWord] = {
        Dictionary(uniqueKeysWithValues: all.map { ($0.term, $0) })
    }()

    static func find(_ term: String) -> CommonWord? {
        byTerm[term.lowercased()]
    }

    static let all: [CommonWord] = [

        // MARK: - A1

        CommonWord(
            term: "eat",
            partOfSpeech: "verb",
            ipa: "/iːt/",
            countability: "N/A",
            definition: "To put food into your mouth, chew it and swallow it.",
            turkishMeaning: "yemek yemek",
            examples: [
                "I eat breakfast every morning.",
                "We don't eat meat on Fridays.",
                "What do you want to eat tonight?",
                "She eats very slowly.",
                "Children should eat more vegetables."
            ],
            level: .a1, topics: [.daily, .food]
        ),
        CommonWord(
            term: "drink",
            partOfSpeech: "verb",
            ipa: "/drɪŋk/",
            countability: "N/A",
            definition: "To take liquid into your mouth and swallow it.",
            turkishMeaning: "içmek",
            examples: [
                "Drink plenty of water every day.",
                "He drinks coffee in the morning.",
                "Don't drink and drive.",
                "She doesn't drink alcohol.",
                "What would you like to drink?"
            ],
            level: .a1, topics: [.daily, .food, .health]
        ),
        CommonWord(
            term: "sleep",
            partOfSpeech: "verb",
            ipa: "/sliːp/",
            countability: "N/A",
            definition: "To rest with your eyes closed and mind unconscious.",
            turkishMeaning: "uyumak",
            examples: [
                "I usually sleep eight hours a night.",
                "The baby is sleeping.",
                "Did you sleep well last night?",
                "Try to sleep early today.",
                "She can't sleep when she's stressed."
            ],
            level: .a1, topics: [.daily, .health]
        ),
        CommonWord(
            term: "water",
            partOfSpeech: "noun",
            ipa: "/ˈwɔːtə/",
            countability: "uncountable",
            definition: "The clear liquid that falls as rain and we drink.",
            turkishMeaning: "su",
            examples: [
                "Can I have a glass of water?",
                "Plants need water and sunlight.",
                "The water in this lake is very clear.",
                "Drink water before exercise.",
                "There is no hot water in the bathroom."
            ],
            level: .a1, topics: [.daily, .food, .nature]
        ),
        CommonWord(
            term: "food",
            partOfSpeech: "noun",
            ipa: "/fuːd/",
            countability: "both",
            definition: "Things that people and animals eat.",
            turkishMeaning: "yemek, yiyecek",
            examples: [
                "Italian food is my favorite.",
                "We need to buy food for the week.",
                "There was lots of food at the party.",
                "She loves trying new foods.",
                "The food in this restaurant is amazing."
            ],
            level: .a1, topics: [.daily, .food]
        ),
        CommonWord(
            term: "family",
            partOfSpeech: "noun",
            ipa: "/ˈfæməli/",
            countability: "countable",
            definition: "A group of people related to each other.",
            turkishMeaning: "aile",
            examples: [
                "My family lives in Istanbul.",
                "She has a big family.",
                "Family is the most important thing.",
                "We are going on a family trip.",
                "He looks like the rest of his family."
            ],
            level: .a1, topics: [.daily, .emotions]
        ),
        CommonWord(
            term: "friend",
            partOfSpeech: "noun",
            ipa: "/frɛnd/",
            countability: "countable",
            definition: "A person you know well and like.",
            turkishMeaning: "arkadaş",
            examples: [
                "She is my best friend.",
                "I made new friends at school.",
                "A real friend is hard to find.",
                "He's a friend from work.",
                "Let's invite a few friends over."
            ],
            level: .a1, topics: [.daily, .emotions]
        ),
        CommonWord(
            term: "house",
            partOfSpeech: "noun",
            ipa: "/haʊs/",
            countability: "countable",
            definition: "A building where a person or family lives.",
            turkishMeaning: "ev",
            examples: [
                "They live in a small house near the sea.",
                "Welcome to our house!",
                "She wants to buy a new house.",
                "There are five rooms in the house.",
                "The house was empty when we arrived."
            ],
            level: .a1, topics: [.daily]
        ),
        CommonWord(
            term: "big",
            partOfSpeech: "adjective",
            ipa: "/bɪɡ/",
            countability: "N/A",
            definition: "Large in size or amount.",
            turkishMeaning: "büyük",
            examples: [
                "He lives in a big city.",
                "That's a big problem.",
                "She wore a big smile.",
                "I had a big breakfast today.",
                "This room isn't big enough."
            ],
            level: .a1, topics: [.general]
        ),
        CommonWord(
            term: "happy",
            partOfSpeech: "adjective",
            ipa: "/ˈhæpi/",
            countability: "N/A",
            definition: "Feeling or showing pleasure or joy.",
            turkishMeaning: "mutlu",
            examples: [
                "She is happy with her new job.",
                "Happy birthday to you!",
                "Reading makes me happy.",
                "He looks really happy today.",
                "I'm happy to help you."
            ],
            level: .a1, topics: [.emotions, .daily]
        ),

        // MARK: - A2

        CommonWord(
            term: "learn",
            partOfSpeech: "verb",
            ipa: "/lɜːn/",
            countability: "N/A",
            definition: "To gain knowledge or a skill through study or practice.",
            turkishMeaning: "öğrenmek",
            examples: [
                "I want to learn Spanish.",
                "Children learn very quickly.",
                "She learned to drive at sixteen.",
                "We learn from our mistakes.",
                "He learned the song in one day."
            ],
            level: .a2, topics: [.academic, .daily]
        ),
        CommonWord(
            term: "arrive",
            partOfSpeech: "verb",
            ipa: "/əˈraɪv/",
            countability: "N/A",
            definition: "To reach a place at the end of a journey.",
            turkishMeaning: "varmak, ulaşmak",
            examples: [
                "We arrived in Paris at 8 p.m.",
                "What time will the train arrive?",
                "She arrived late to the meeting.",
                "They arrived safely.",
                "Please call me when you arrive."
            ],
            level: .a2, topics: [.travel, .daily]
        ),
        CommonWord(
            term: "travel",
            partOfSpeech: "verb",
            ipa: "/ˈtrævl/",
            countability: "N/A",
            definition: "To go from one place to another, often far away.",
            turkishMeaning: "seyahat etmek",
            examples: [
                "I love to travel in summer.",
                "She travels a lot for work.",
                "We traveled around Europe last year.",
                "He has traveled to many countries.",
                "Travel broadens the mind."
            ],
            level: .a2, topics: [.travel]
        ),
        CommonWord(
            term: "listen",
            partOfSpeech: "verb",
            ipa: "/ˈlɪsn/",
            countability: "N/A",
            definition: "To pay attention to sounds, especially someone speaking.",
            turkishMeaning: "dinlemek",
            examples: [
                "Please listen carefully.",
                "I love listening to music.",
                "She listens to podcasts every morning.",
                "He didn't listen to my advice.",
                "Listen — can you hear that?"
            ],
            level: .a2, topics: [.daily, .general]
        ),
        CommonWord(
            term: "weather",
            partOfSpeech: "noun",
            ipa: "/ˈwɛðə/",
            countability: "uncountable",
            definition: "The state of the air, like sun, rain, or wind.",
            turkishMeaning: "hava durumu",
            examples: [
                "The weather is nice today.",
                "I check the weather every morning.",
                "Bad weather delayed our flight.",
                "What's the weather like in Istanbul?",
                "We had perfect weather for the picnic."
            ],
            level: .a2, topics: [.daily, .nature]
        ),
        CommonWord(
            term: "holiday",
            partOfSpeech: "noun",
            ipa: "/ˈhɒlədeɪ/",
            countability: "countable",
            definition: "A period of time when you don't work and often travel.",
            turkishMeaning: "tatil",
            examples: [
                "We went to Italy on holiday.",
                "I need a long holiday.",
                "Schools close for the summer holiday.",
                "Where are you going for the holidays?",
                "He spent his holiday reading books."
            ],
            level: .a2, topics: [.travel, .daily]
        ),
        CommonWord(
            term: "money",
            partOfSpeech: "noun",
            ipa: "/ˈmʌni/",
            countability: "uncountable",
            definition: "Coins and paper notes used to buy things.",
            turkishMeaning: "para",
            examples: [
                "I don't have enough money.",
                "She earns good money at her new job.",
                "Money isn't everything.",
                "Can I borrow some money?",
                "He saves money every month."
            ],
            level: .a2, topics: [.business, .daily]
        ),
        CommonWord(
            term: "busy",
            partOfSpeech: "adjective",
            ipa: "/ˈbɪzi/",
            countability: "N/A",
            definition: "Having a lot of things to do.",
            turkishMeaning: "meşgul, yoğun",
            examples: [
                "I'm busy at the moment.",
                "She had a busy day at work.",
                "The streets were busy with tourists.",
                "He's too busy to call me back.",
                "Can we meet next week? This one is busy."
            ],
            level: .a2, topics: [.daily, .work]
        ),
        CommonWord(
            term: "ready",
            partOfSpeech: "adjective",
            ipa: "/ˈrɛdi/",
            countability: "N/A",
            definition: "Prepared and able to start something.",
            turkishMeaning: "hazır",
            examples: [
                "Are you ready to go?",
                "Dinner is ready!",
                "She is ready for the exam.",
                "The room will be ready in an hour.",
                "I'm ready when you are."
            ],
            level: .a2, topics: [.general, .daily]
        ),
        CommonWord(
            term: "tired",
            partOfSpeech: "adjective",
            ipa: "/ˈtaɪəd/",
            countability: "N/A",
            definition: "Needing rest or sleep.",
            turkishMeaning: "yorgun",
            examples: [
                "I'm too tired to cook tonight.",
                "She looks tired after the long trip.",
                "The kids are tired of waiting.",
                "He went to bed tired but happy.",
                "I'm getting tired of this game."
            ],
            level: .a2, topics: [.health, .emotions]
        ),
        CommonWord(
            term: "decide",
            partOfSpeech: "verb",
            ipa: "/dɪˈsaɪd/",
            countability: "N/A",
            definition: "To choose after thinking about options.",
            turkishMeaning: "karar vermek",
            examples: [
                "They decided to get married next summer.",
                "I cannot decide what to wear.",
                "We need to decide quickly.",
                "She decided against accepting the offer.",
                "The court will decide the case tomorrow."
            ],
            level: .a2, topics: [.daily, .general]
        ),
        CommonWord(
            term: "difficult",
            partOfSpeech: "adjective",
            ipa: "/ˈdɪfɪkəlt/",
            countability: "N/A",
            definition: "Needing much effort or skill to do or understand.",
            turkishMeaning: "zor, güç",
            examples: [
                "Math can be difficult for some students.",
                "It is difficult to say goodbye.",
                "She is going through a difficult time.",
                "The instructions are too difficult to follow.",
                "Don't make life more difficult than it needs to be."
            ],
            level: .a2, topics: [.general]
        ),
        CommonWord(
            term: "follow",
            partOfSpeech: "verb",
            ipa: "/ˈfɒləʊ/",
            countability: "N/A",
            definition: "To go after, or to do what is told.",
            turkishMeaning: "takip etmek, izlemek",
            examples: [
                "The dog followed me home.",
                "Please follow the instructions carefully.",
                "I'll follow you to the airport.",
                "She follows her favorite team online.",
                "Many problems follow from poor planning."
            ],
            level: .a2, topics: [.general]
        ),
        CommonWord(
            term: "important",
            partOfSpeech: "adjective",
            ipa: "/ɪmˈpɔːtnt/",
            countability: "N/A",
            definition: "Having great value, meaning, or effect.",
            turkishMeaning: "önemli",
            examples: [
                "Family is the most important thing to her.",
                "It's important to drink enough water.",
                "He plays an important role in the company.",
                "An important meeting starts in five minutes.",
                "Saving money is important for the future."
            ],
            level: .a2, topics: [.general]
        ),
        CommonWord(
            term: "possible",
            partOfSpeech: "adjective",
            ipa: "/ˈpɒsəbl/",
            countability: "N/A",
            definition: "Able to happen, be done, or exist.",
            turkishMeaning: "mümkün, olası",
            examples: [
                "Is it possible to change my reservation?",
                "Anything is possible with hard work.",
                "We'll come as soon as possible.",
                "It's possible that he forgot.",
                "Please reply at your earliest possible convenience."
            ],
            level: .a2, topics: [.general]
        ),
        CommonWord(
            term: "prepare",
            partOfSpeech: "verb",
            ipa: "/prɪˈpɛə(r)/",
            countability: "N/A",
            definition: "To make ready in advance.",
            turkishMeaning: "hazırlamak",
            examples: [
                "She is preparing dinner.",
                "Students should prepare for the exam.",
                "We need to prepare a backup plan.",
                "He prepared the room for the guests.",
                "Always prepare for the unexpected."
            ],
            level: .a2, topics: [.daily, .academic]
        ),
        CommonWord(
            term: "probably",
            partOfSpeech: "adverb",
            ipa: "/ˈprɒbəbli/",
            countability: "N/A",
            definition: "Almost certainly; very likely.",
            turkishMeaning: "muhtemelen, büyük ihtimalle",
            examples: [
                "It will probably rain tomorrow.",
                "She is probably the best in the team.",
                "He probably forgot about the meeting.",
                "We will probably leave early.",
                "That's probably true."
            ],
            level: .a2, topics: [.general]
        ),
        CommonWord(
            term: "understand",
            partOfSpeech: "verb",
            ipa: "/ˌʌndəˈstænd/",
            countability: "N/A",
            definition: "To know the meaning of or feel sympathy for.",
            turkishMeaning: "anlamak",
            examples: [
                "I understand your concerns.",
                "Do you understand the question?",
                "She doesn't understand French.",
                "Now I understand why he was upset.",
                "It's easy to understand once you try."
            ],
            level: .a2, topics: [.general, .academic]
        ),
        CommonWord(
            term: "useful",
            partOfSpeech: "adjective",
            ipa: "/ˈjuːsfl/",
            countability: "N/A",
            definition: "Able to be used for a practical purpose.",
            turkishMeaning: "yararlı, kullanışlı",
            examples: [
                "This tool is very useful in the kitchen.",
                "She gave me some useful advice.",
                "Knowing a second language is useful.",
                "These tips are surprisingly useful.",
                "Could you make yourself useful?"
            ],
            level: .a2, topics: [.general]
        ),

        // MARK: - B1

        CommonWord(
            term: "available",
            partOfSpeech: "adjective",
            ipa: "/əˈveɪləbl/",
            countability: "N/A",
            definition: "Able to be used or obtained; free to do something.",
            turkishMeaning: "mevcut, müsait",
            examples: [
                "The new model will be available next month.",
                "Are you available for a quick call today?",
                "Tickets are no longer available online.",
                "There are several options available to you.",
                "The doctor is not available right now."
            ],
            level: .b1, topics: [.work, .daily]
        ),
        CommonWord(
            term: "common",
            partOfSpeech: "adjective",
            ipa: "/ˈkɒmən/",
            countability: "N/A",
            definition: "Happening often; shared by many people.",
            turkishMeaning: "yaygın, ortak",
            examples: [
                "The common cold spreads easily in winter.",
                "Honesty and trust are common values.",
                "Such mistakes are very common among beginners.",
                "We have a lot in common.",
                "Owls are common in this forest."
            ],
            level: .b1, topics: [.general]
        ),
        CommonWord(
            term: "decision",
            partOfSpeech: "noun",
            ipa: "/dɪˈsɪʒn/",
            countability: "countable",
            definition: "A choice or judgement made after consideration.",
            turkishMeaning: "karar",
            examples: [
                "Quitting his job was a difficult decision.",
                "We respect your decision.",
                "The decision is yours to make.",
                "She regrets her decision.",
                "It was a wise decision in the end."
            ],
            level: .b1, topics: [.business, .general]
        ),
        CommonWord(
            term: "effort",
            partOfSpeech: "noun",
            ipa: "/ˈɛfət/",
            countability: "both",
            definition: "The energy or work used to do something.",
            turkishMeaning: "çaba, gayret",
            examples: [
                "Success requires consistent effort.",
                "Make an effort to be on time.",
                "All her efforts were finally rewarded.",
                "It took a lot of effort to finish the project.",
                "Thanks for your effort today."
            ],
            level: .b1, topics: [.work, .general]
        ),
        CommonWord(
            term: "experience",
            partOfSpeech: "noun",
            ipa: "/ɪkˈspɪəriəns/",
            countability: "both",
            definition: "Knowledge or skill gained from doing something.",
            turkishMeaning: "deneyim, tecrübe",
            examples: [
                "She has years of experience in marketing.",
                "Living abroad was an unforgettable experience.",
                "The experience taught me to be patient.",
                "We learn from every experience.",
                "Do you have any teaching experience?"
            ],
            level: .b1, topics: [.work, .general]
        ),
        CommonWord(
            term: "explain",
            partOfSpeech: "verb",
            ipa: "/ɪkˈspleɪn/",
            countability: "N/A",
            definition: "To make something clear by giving details.",
            turkishMeaning: "açıklamak",
            examples: [
                "Can you explain how this works?",
                "She explained the problem to her teacher.",
                "He couldn't explain his decision.",
                "Let me explain what I meant.",
                "The doctor explained the diagnosis carefully."
            ],
            level: .b1, topics: [.academic, .general]
        ),
        CommonWord(
            term: "however",
            partOfSpeech: "adverb",
            ipa: "/haʊˈɛvə(r)/",
            countability: "N/A",
            definition: "Used to introduce a contrasting idea.",
            turkishMeaning: "ancak, bununla birlikte",
            examples: [
                "The plan is risky; however, it might work.",
                "However hard he tried, he could not win.",
                "She is talented. However, she lacks discipline.",
                "However, no one was sure of the answer.",
                "It is cold today; however, we will go out."
            ],
            level: .b1, topics: [.academic]
        ),
        CommonWord(
            term: "improve",
            partOfSpeech: "verb",
            ipa: "/ɪmˈpruːv/",
            countability: "N/A",
            definition: "To make or become better.",
            turkishMeaning: "geliştirmek, iyileşmek",
            examples: [
                "I want to improve my English.",
                "The weather is improving.",
                "Practice will improve your skills.",
                "Sales have improved this quarter.",
                "She improved her score by ten points."
            ],
            level: .b1, topics: [.work, .academic]
        ),
        CommonWord(
            term: "include",
            partOfSpeech: "verb",
            ipa: "/ɪnˈkluːd/",
            countability: "N/A",
            definition: "To contain or take in as a part.",
            turkishMeaning: "içermek, dahil etmek",
            examples: [
                "The price includes breakfast.",
                "Please include your contact details.",
                "Our team includes five engineers.",
                "Don't forget to include the children.",
                "The book includes many illustrations."
            ],
            level: .b1, topics: [.general]
        ),
        CommonWord(
            term: "increase",
            partOfSpeech: "verb",
            ipa: "/ɪnˈkriːs/",
            countability: "N/A",
            definition: "To become or make larger or greater.",
            turkishMeaning: "artmak, artırmak",
            examples: [
                "Sales increased by 20% this year.",
                "We need to increase our efforts.",
                "Stress can increase your heart rate.",
                "The population continues to increase.",
                "They decided to increase the budget."
            ],
            level: .b1, topics: [.business]
        ),
        CommonWord(
            term: "necessary",
            partOfSpeech: "adjective",
            ipa: "/ˈnɛsəsəri/",
            countability: "N/A",
            definition: "Needed in order for something to happen.",
            turkishMeaning: "gerekli, zorunlu",
            examples: [
                "Take all necessary precautions.",
                "It is necessary to wear a helmet.",
                "He made the necessary changes.",
                "Sleep is necessary for the brain.",
                "I will do whatever is necessary."
            ],
            level: .b1, topics: [.general]
        ),
        CommonWord(
            term: "provide",
            partOfSpeech: "verb",
            ipa: "/prəˈvaɪd/",
            countability: "N/A",
            definition: "To give something to someone.",
            turkishMeaning: "sağlamak, sunmak",
            examples: [
                "The hotel provides free breakfast.",
                "She provided helpful feedback.",
                "Parents must provide for their children.",
                "This book provides useful tips.",
                "The website provides reliable information."
            ],
            level: .b1, topics: [.business, .general]
        ),
        CommonWord(
            term: "reach",
            partOfSpeech: "verb",
            ipa: "/riːtʃ/",
            countability: "N/A",
            definition: "To arrive at a place or contact someone.",
            turkishMeaning: "ulaşmak, varmak",
            examples: [
                "We reached the summit at sunrise.",
                "You can reach me on my mobile.",
                "She reached for the salt.",
                "The temperature reached forty degrees.",
                "Their voices could be heard from a great distance."
            ],
            level: .b1, topics: [.travel, .general]
        ),
        CommonWord(
            term: "recommend",
            partOfSpeech: "verb",
            ipa: "/ˌrɛkəˈmɛnd/",
            countability: "N/A",
            definition: "To advise someone to do something.",
            turkishMeaning: "tavsiye etmek, önermek",
            examples: [
                "I recommend trying the pasta.",
                "Doctors recommend regular exercise.",
                "Can you recommend a good book?",
                "She was recommended for the promotion.",
                "I would not recommend driving in this weather."
            ],
            level: .b1, topics: [.daily, .business]
        ),
        CommonWord(
            term: "result",
            partOfSpeech: "noun",
            ipa: "/rɪˈzʌlt/",
            countability: "countable",
            definition: "An outcome caused by something.",
            turkishMeaning: "sonuç",
            examples: [
                "The result of the match was a draw.",
                "Hard work brings good results.",
                "Test results will be ready tomorrow.",
                "What was the result of the meeting?",
                "Poor planning leads to poor results."
            ],
            level: .b1, topics: [.academic, .general]
        ),
        CommonWord(
            term: "support",
            partOfSpeech: "verb",
            ipa: "/səˈpɔːt/",
            countability: "N/A",
            definition: "To help or encourage someone or something.",
            turkishMeaning: "desteklemek",
            examples: [
                "My family supports me in everything.",
                "These columns support the roof.",
                "She supports a charity for children.",
                "We support open-source projects.",
                "The evidence supports the theory."
            ],
            level: .b1, topics: [.work, .general]
        ),

        // MARK: - B2

        CommonWord(
            term: "achieve",
            partOfSpeech: "verb",
            ipa: "/əˈtʃiːv/",
            countability: "N/A",
            definition: "To successfully reach a goal through effort.",
            turkishMeaning: "başarmak, elde etmek",
            examples: [
                "She worked hard to achieve her dream of becoming a doctor.",
                "It is difficult to achieve perfect balance in life.",
                "We can achieve more by working together.",
                "He achieved a personal best at the marathon.",
                "Companies achieve growth by investing in people."
            ],
            level: .b2, topics: [.work, .business]
        ),
        CommonWord(
            term: "benefit",
            partOfSpeech: "noun",
            ipa: "/ˈbɛnɪfɪt/",
            countability: "countable",
            definition: "An advantage or positive effect gained from something.",
            turkishMeaning: "fayda, yarar",
            examples: [
                "Regular exercise has many health benefits.",
                "One benefit of remote work is flexibility.",
                "The new policy will benefit small businesses.",
                "Employees receive generous benefits at this company.",
                "I see no real benefit in changing the plan."
            ],
            level: .b2, topics: [.business, .work]
        ),
        CommonWord(
            term: "challenge",
            partOfSpeech: "noun",
            ipa: "/ˈtʃælɪndʒ/",
            countability: "countable",
            definition: "A difficult task that tests one's ability.",
            turkishMeaning: "zorluk, meydan okuma",
            examples: [
                "Learning a new language is always a challenge.",
                "He faced many challenges on his journey.",
                "I love the challenge of solving complex problems.",
                "Climate change is the biggest challenge of our time.",
                "She accepted the challenge without hesitation."
            ],
            level: .b2, topics: [.work, .general]
        ),
        CommonWord(
            term: "consider",
            partOfSpeech: "verb",
            ipa: "/kənˈsɪdə(r)/",
            countability: "N/A",
            definition: "To think carefully about something before deciding.",
            turkishMeaning: "düşünmek, göz önünde bulundurmak",
            examples: [
                "Please consider my proposal before refusing.",
                "She is considering moving to another city.",
                "We must consider all the possibilities.",
                "He is considered one of the best in his field.",
                "Have you considered the consequences?"
            ],
            level: .b2, topics: [.academic, .business]
        ),
        CommonWord(
            term: "essential",
            partOfSpeech: "adjective",
            ipa: "/ɪˈsɛnʃəl/",
            countability: "N/A",
            definition: "Absolutely necessary; extremely important.",
            turkishMeaning: "temel, gerekli",
            examples: [
                "Water is essential for life.",
                "It is essential to read the instructions first.",
                "Trust is essential in any relationship.",
                "These vitamins are essential to good health.",
                "Sleep is essential for recovery."
            ],
            level: .b2, topics: [.academic, .general]
        ),
        CommonWord(
            term: "evidence",
            partOfSpeech: "noun",
            ipa: "/ˈɛvɪdəns/",
            countability: "uncountable",
            definition: "Facts or information showing if something is true.",
            turkishMeaning: "kanıt, delil",
            examples: [
                "There is no evidence that he was lying.",
                "The evidence was overwhelming.",
                "Police are gathering evidence at the scene.",
                "Recent studies provide strong evidence for the theory.",
                "We need more evidence before drawing conclusions."
            ],
            level: .b2, topics: [.academic]
        ),
        CommonWord(
            term: "focus",
            partOfSpeech: "verb",
            ipa: "/ˈfəʊkəs/",
            countability: "N/A",
            definition: "To pay close attention to one thing.",
            turkishMeaning: "odaklanmak",
            examples: [
                "Please focus on your work.",
                "We need to focus on the main issue.",
                "She focused her energy on writing the book.",
                "I find it hard to focus in noisy places.",
                "The team is focused on winning the cup."
            ],
            level: .b2, topics: [.work, .academic]
        ),
        CommonWord(
            term: "knowledge",
            partOfSpeech: "noun",
            ipa: "/ˈnɒlɪdʒ/",
            countability: "uncountable",
            definition: "Information and skills gained through learning.",
            turkishMeaning: "bilgi",
            examples: [
                "Knowledge is power.",
                "She has deep knowledge of history.",
                "The course offers practical knowledge.",
                "He shared his knowledge generously.",
                "Without knowledge, mistakes are inevitable."
            ],
            level: .b2, topics: [.academic]
        ),
        CommonWord(
            term: "manage",
            partOfSpeech: "verb",
            ipa: "/ˈmænɪdʒ/",
            countability: "N/A",
            definition: "To succeed in doing something difficult or to be in charge.",
            turkishMeaning: "yönetmek, başa çıkmak",
            examples: [
                "She manages a team of ten people.",
                "How do you manage your time so well?",
                "We managed to finish before the deadline.",
                "He manages stress through meditation.",
                "Can you manage on your own?"
            ],
            level: .b2, topics: [.business, .work]
        ),
        CommonWord(
            term: "opportunity",
            partOfSpeech: "noun",
            ipa: "/ˌɒpəˈtjuːnəti/",
            countability: "countable",
            definition: "A chance for progress or advancement.",
            turkishMeaning: "fırsat",
            examples: [
                "This job is a great opportunity for growth.",
                "Don't miss the opportunity to travel.",
                "She seized every opportunity to learn.",
                "Opportunities like this are rare.",
                "We had no opportunity to talk yesterday."
            ],
            level: .b2, topics: [.work, .business]
        ),
        CommonWord(
            term: "purpose",
            partOfSpeech: "noun",
            ipa: "/ˈpɜːpəs/",
            countability: "countable",
            definition: "The reason for which something is done.",
            turkishMeaning: "amaç, maksat",
            examples: [
                "What is the purpose of this meeting?",
                "She lives with a sense of purpose.",
                "I did not say it on purpose.",
                "The purpose of the trip is to learn.",
                "Every law has a purpose."
            ],
            level: .b2, topics: [.academic, .general]
        ),
        CommonWord(
            term: "realize",
            partOfSpeech: "verb",
            ipa: "/ˈrɪəlaɪz/",
            countability: "N/A",
            definition: "To become aware of something or make real.",
            turkishMeaning: "fark etmek, gerçekleştirmek",
            examples: [
                "I didn't realize how late it was.",
                "She realized her mistake immediately.",
                "He finally realized his dream.",
                "Do you realize what you've done?",
                "We realized profits of over a million."
            ],
            level: .b2, topics: [.general]
        ),
        CommonWord(
            term: "responsibility",
            partOfSpeech: "noun",
            ipa: "/rɪˌspɒnsəˈbɪləti/",
            countability: "both",
            definition: "A duty to deal with something or someone.",
            turkishMeaning: "sorumluluk",
            examples: [
                "Parents have a responsibility to their children.",
                "She takes full responsibility for the error.",
                "Driving is a big responsibility.",
                "Sharing responsibilities makes work easier.",
                "It is your responsibility to lock the door."
            ],
            level: .b2, topics: [.work, .business]
        ),
        CommonWord(
            term: "succeed",
            partOfSpeech: "verb",
            ipa: "/səkˈsiːd/",
            countability: "N/A",
            definition: "To achieve a desired aim or result.",
            turkishMeaning: "başarmak, başarılı olmak",
            examples: [
                "He worked hard to succeed in business.",
                "Plans rarely succeed without effort.",
                "She succeeded where others had failed.",
                "We will succeed if we stay focused.",
                "Few startups succeed in their first year."
            ],
            level: .b2, topics: [.work, .business]
        ),
        CommonWord(
            term: "suggest",
            partOfSpeech: "verb",
            ipa: "/səˈdʒɛst/",
            countability: "N/A",
            definition: "To put forward an idea for consideration.",
            turkishMeaning: "önermek, ima etmek",
            examples: [
                "I suggest we leave early.",
                "What do you suggest doing tonight?",
                "Her smile suggested she was happy.",
                "The data suggests a clear trend.",
                "He suggested an alternative route."
            ],
            level: .b2, topics: [.business, .academic]
        ),
        CommonWord(
            term: "therefore",
            partOfSpeech: "adverb",
            ipa: "/ˈðɛəfɔː(r)/",
            countability: "N/A",
            definition: "For that reason; as a result.",
            turkishMeaning: "bu yüzden, dolayısıyla",
            examples: [
                "He was tired and therefore went to bed.",
                "She studied hard and therefore passed easily.",
                "It is raining; therefore we should stay in.",
                "The data is incomplete and therefore unreliable.",
                "I think, therefore I am."
            ],
            level: .b2, topics: [.academic]
        ),
        CommonWord(
            term: "valuable",
            partOfSpeech: "adjective",
            ipa: "/ˈvæljuəbl/",
            countability: "N/A",
            definition: "Worth a lot of money or very useful.",
            turkishMeaning: "değerli, kıymetli",
            examples: [
                "Time is the most valuable thing we have.",
                "She gave me some valuable advice.",
                "The painting is extremely valuable.",
                "Experience is more valuable than money.",
                "He made a valuable contribution to the team."
            ],
            level: .b2, topics: [.business, .general]
        ),
        CommonWord(
            term: "willing",
            partOfSpeech: "adjective",
            ipa: "/ˈwɪlɪŋ/",
            countability: "N/A",
            definition: "Ready and prepared to do something.",
            turkishMeaning: "istekli, gönüllü",
            examples: [
                "She is always willing to help.",
                "Are you willing to take the risk?",
                "He is willing to learn new things.",
                "I am not willing to wait any longer.",
                "We need willing volunteers."
            ],
            level: .b2, topics: [.work, .emotions]
        ),

        // MARK: - C1

        CommonWord(
            term: "endeavor",
            partOfSpeech: "noun",
            ipa: "/ɪnˈdɛvə(r)/",
            countability: "countable",
            definition: "A serious attempt to achieve a goal.",
            turkishMeaning: "girişim, çaba",
            examples: [
                "Climbing Everest is a dangerous endeavor.",
                "Their endeavor to launch a startup paid off.",
                "She supported his every endeavor.",
                "Scientific endeavor requires patience.",
                "It was a noble endeavor that ended in success."
            ],
            level: .c1, topics: [.business, .academic]
        ),
        CommonWord(
            term: "perspective",
            partOfSpeech: "noun",
            ipa: "/pəˈspɛktɪv/",
            countability: "countable",
            definition: "A particular way of viewing something.",
            turkishMeaning: "bakış açısı",
            examples: [
                "Travel gives you a new perspective on life.",
                "From my perspective, the plan is fair.",
                "Try to see things from her perspective.",
                "Time often changes our perspective.",
                "We need to keep things in perspective."
            ],
            level: .c1, topics: [.academic, .emotions]
        ),
        CommonWord(
            term: "resilient",
            partOfSpeech: "adjective",
            ipa: "/rɪˈzɪliənt/",
            countability: "N/A",
            definition: "Able to recover quickly from difficulties.",
            turkishMeaning: "dirençli, esnek",
            examples: [
                "Children are remarkably resilient.",
                "A resilient economy bounces back quickly.",
                "She remained resilient despite setbacks.",
                "Bamboo is resilient and bends without breaking.",
                "Resilient leaders inspire confidence."
            ],
            level: .c1, topics: [.emotions, .business]
        ),
        CommonWord(
            term: "thorough",
            partOfSpeech: "adjective",
            ipa: "/ˈθʌrə/",
            countability: "N/A",
            definition: "Complete and careful in detail.",
            turkishMeaning: "kapsamlı, titiz",
            examples: [
                "She did a thorough job of cleaning.",
                "Thorough preparation is the key to success.",
                "The doctor performed a thorough examination.",
                "Make a thorough check before leaving.",
                "He has a thorough knowledge of the law."
            ],
            level: .c1, topics: [.academic, .work]
        ),
        CommonWord(
            term: "vague",
            partOfSpeech: "adjective",
            ipa: "/veɪɡ/",
            countability: "N/A",
            definition: "Not clearly expressed or seen.",
            turkishMeaning: "belirsiz, müphem",
            examples: [
                "He gave a vague answer to my question.",
                "I have only a vague memory of the place.",
                "Her instructions were too vague to follow.",
                "There was a vague smell of smoke in the air.",
                "Try to avoid vague language in essays."
            ],
            level: .c1, topics: [.academic]
        ),

        // MARK: - C2

        CommonWord(
            term: "ephemeral",
            partOfSpeech: "adjective",
            ipa: "/ɪˈfɛmərəl/",
            countability: "N/A",
            definition: "Lasting for a very short time.",
            turkishMeaning: "kısa ömürlü, geçici",
            examples: [
                "Cherry blossoms are famously ephemeral.",
                "Fame can be ephemeral.",
                "The artist captured the ephemeral light of dawn.",
                "Their happiness was ephemeral and faded by morning.",
                "Snowflakes have an ephemeral beauty."
            ],
            level: .c2, topics: [.nature, .academic]
        ),
        CommonWord(
            term: "ubiquitous",
            partOfSpeech: "adjective",
            ipa: "/juːˈbɪkwɪtəs/",
            countability: "N/A",
            definition: "Present, appearing, or found everywhere.",
            turkishMeaning: "her yerde bulunan, yaygın",
            examples: [
                "Smartphones have become ubiquitous in modern life.",
                "Coffee shops are ubiquitous in this neighborhood.",
                "The ubiquitous influence of social media is undeniable.",
                "Plastic is ubiquitous in today's oceans.",
                "Their logo is ubiquitous on city streets."
            ],
            level: .c2, topics: [.technology, .academic]
        ),
        CommonWord(
            term: "meticulous",
            partOfSpeech: "adjective",
            ipa: "/məˈtɪkjʊləs/",
            countability: "N/A",
            definition: "Showing great attention to detail; very careful and precise.",
            turkishMeaning: "titiz, özenli",
            examples: [
                "She is meticulous about her appearance.",
                "His notes were meticulous and easy to follow.",
                "The watch was assembled with meticulous care.",
                "Surgeons must be meticulous in every move.",
                "Their meticulous research paid off."
            ],
            level: .c2, topics: [.work, .academic]
        ),

        // MARK: - TOEFL Vocabulary

        CommonWord(
            term: "abundant",
            partOfSpeech: "adjective",
            ipa: "/əˈbʌndənt/",
            countability: "N/A",
            definition: "Present in large quantities; more than enough.",
            turkishMeaning: "bol, çok",
            examples: [
                "Living close to a lake means we have an abundant supply of water.",
                "The forest had an abundant variety of birds.",
                "Apples were abundant during the harvest season.",
                "There is abundant evidence to support this theory.",
                "She received abundant praise for her speech."
            ],
            level: .c1, topics: [.academic, .nature]
        ),
        CommonWord(
            term: "accumulate",
            partOfSpeech: "verb",
            ipa: "/əˈkjuːmjəleɪt/",
            countability: "N/A",
            definition: "To gradually collect or gather over time.",
            turkishMeaning: "biriktirmek, toplamak",
            examples: [
                "Each fall, leaves accumulate in our driveway.",
                "Dust accumulates quickly on these shelves.",
                "He accumulated a small fortune over the years.",
                "Snow accumulated on the rooftops overnight.",
                "Investors hope their savings will accumulate interest."
            ],
            level: .b2, topics: [.academic, .business]
        ),
        CommonWord(
            term: "accurate",
            partOfSpeech: "adjective",
            ipa: "/ˈækjərət/",
            countability: "N/A",
            definition: "Correct and free from errors.",
            turkishMeaning: "doğru, kesin",
            examples: [
                "Make sure your address is accurate before submitting your online order.",
                "The map is not very accurate.",
                "We need accurate measurements for the project.",
                "His prediction turned out to be accurate.",
                "Please give an accurate description of the event."
            ],
            level: .b2, topics: [.academic, .work]
        ),
        CommonWord(
            term: "accustomed",
            partOfSpeech: "adjective",
            ipa: "/əˈkʌstəmd/",
            countability: "N/A",
            definition: "Used to something through repeated experience.",
            turkishMeaning: "alışkın, alışmış",
            examples: [
                "Having 8AM classes means I'm accustomed to getting up early.",
                "She is accustomed to working long hours.",
                "He grew accustomed to the cold weather.",
                "They became accustomed to city life quickly.",
                "I'm not accustomed to such formal dinners."
            ],
            level: .b2, topics: [.daily]
        ),
        CommonWord(
            term: "acquire",
            partOfSpeech: "verb",
            ipa: "/əˈkwaɪə/",
            countability: "N/A",
            definition: "To come into possession of something.",
            turkishMeaning: "edinmek, elde etmek",
            examples: [
                "When my grandmother died, I acquired her cookbook collection.",
                "The company acquired three smaller competitors.",
                "He acquired a taste for olives while in Greece.",
                "You can acquire new skills through practice.",
                "She recently acquired a vintage car."
            ],
            level: .b2, topics: [.business, .academic]
        ),
        CommonWord(
            term: "adamant",
            partOfSpeech: "adjective",
            ipa: "/ˈædəmənt/",
            countability: "N/A",
            definition: "Refusing to change one's opinion or decision.",
            turkishMeaning: "kararlı, inatçı",
            examples: [
                "The defendant was adamant that he was innocent.",
                "She was adamant about going alone.",
                "He remained adamant despite our objections.",
                "Her parents were adamant that she finish college.",
                "I'm adamant that we should leave early."
            ],
            level: .c2, topics: [.emotions]
        ),
        CommonWord(
            term: "adequate",
            partOfSpeech: "adjective",
            ipa: "/ˈædɪkwət/",
            countability: "N/A",
            definition: "Enough to suit your needs; sufficient.",
            turkishMeaning: "yeterli, kâfi",
            examples: [
                "Our house isn't big, but it's adequate for the two of us.",
                "The salary is adequate for my needs.",
                "His skills are adequate for the job.",
                "Make sure you get adequate sleep.",
                "Their training was barely adequate."
            ],
            level: .b2, topics: [.general]
        ),
        CommonWord(
            term: "adjacent",
            partOfSpeech: "adjective",
            ipa: "/əˈdʒeɪsnt/",
            countability: "N/A",
            definition: "Close to or next to something.",
            turkishMeaning: "bitişik, komşu",
            examples: [
                "The park is adjacent to the school.",
                "Our offices are adjacent to each other.",
                "The hotel is adjacent to the airport.",
                "He sat in the adjacent chair.",
                "The two countries are adjacent."
            ],
            level: .c1, topics: [.academic]
        ),
        CommonWord(
            term: "adjust",
            partOfSpeech: "verb",
            ipa: "/əˈdʒʌst/",
            countability: "N/A",
            definition: "To change something slightly to improve it.",
            turkishMeaning: "ayarlamak, uyarlamak",
            examples: [
                "The bike seat may be too high; you'll probably need to adjust it.",
                "Adjust the volume on the speakers.",
                "It took time to adjust to the new city.",
                "She adjusted her glasses and continued reading.",
                "We had to adjust our plans."
            ],
            level: .b2, topics: [.daily, .work]
        ),
        CommonWord(
            term: "advantage",
            partOfSpeech: "noun",
            ipa: "/ədˈvɑːntɪdʒ/",
            countability: "countable",
            definition: "Something that makes it easier to achieve success.",
            turkishMeaning: "avantaj, üstünlük",
            examples: [
                "His height gives him an advantage in basketball.",
                "Speaking two languages is a great advantage.",
                "We should take advantage of this opportunity.",
                "Working from home has its advantages.",
                "Knowledge is your biggest advantage."
            ],
            level: .b2, topics: [.business, .general]
        ),
        CommonWord(
            term: "advocate",
            partOfSpeech: "verb",
            ipa: "/ˈædvəkeɪt/",
            countability: "N/A",
            definition: "To publicly support or recommend.",
            turkishMeaning: "savunmak, desteklemek",
            examples: [
                "My aunt is a major advocate for women's rights.",
                "He advocates a healthier lifestyle.",
                "She advocated for better schools.",
                "The doctor advocates daily exercise.",
                "They advocate change through peaceful means."
            ],
            level: .c1, topics: [.business, .academic]
        ),
        CommonWord(
            term: "adverse",
            partOfSpeech: "adjective",
            ipa: "/ˈædvɜːs/",
            countability: "N/A",
            definition: "Unfavorable; against one's desires.",
            turkishMeaning: "olumsuz, ters",
            examples: [
                "I had an adverse reaction to my medication and had to stop taking it.",
                "Despite adverse conditions, they completed the climb.",
                "The new policy had adverse effects on small businesses.",
                "She was unprepared for the adverse weather.",
                "His comments had an adverse impact on team morale."
            ],
            level: .c1, topics: [.health, .academic]
        ),
        CommonWord(
            term: "aggregate",
            partOfSpeech: "verb",
            ipa: "/ˈæɡrɪɡeɪt/",
            countability: "N/A",
            definition: "To combine separate elements into a total.",
            turkishMeaning: "toplamak, bir araya getirmek",
            examples: [
                "We should aggregate our resources to share them more easily.",
                "The website aggregates news from many sources.",
                "Let's aggregate the data before making conclusions.",
                "The report aggregates findings from ten studies.",
                "Their efforts were aggregated into one campaign."
            ],
            level: .c1, topics: [.academic, .business]
        ),
        CommonWord(
            term: "aggressive",
            partOfSpeech: "adjective",
            ipa: "/əˈɡrɛsɪv/",
            countability: "N/A",
            definition: "Assertive, pushy, or hostile.",
            turkishMeaning: "saldırgan, agresif",
            examples: [
                "The salesperson was very aggressive when trying to get us to buy the television.",
                "Their aggressive driving made me nervous.",
                "He took an aggressive stance in the debate.",
                "The dog became aggressive when threatened.",
                "She used aggressive tactics to win the case."
            ],
            level: .b2, topics: [.emotions, .business]
        ),
        CommonWord(
            term: "allocate",
            partOfSpeech: "verb",
            ipa: "/ˈæləkeɪt/",
            countability: "N/A",
            definition: "To set aside for a specific purpose.",
            turkishMeaning: "tahsis etmek, ayırmak",
            examples: [
                "The village needs to allocate funds for building the new school.",
                "How much time did you allocate for studying?",
                "Resources were allocated to research.",
                "Please allocate two hours for this meeting.",
                "The government allocated money to disaster relief."
            ],
            level: .c1, topics: [.business, .work]
        ),
        CommonWord(
            term: "alternative",
            partOfSpeech: "noun",
            ipa: "/ɔːlˈtɜːnətɪv/",
            countability: "countable",
            definition: "Another option or choice.",
            turkishMeaning: "alternatif, seçenek",
            examples: [
                "If the ATM is broken, an alternative solution is to stop by the bank.",
                "Is there a vegetarian alternative on the menu?",
                "We had no alternative but to wait.",
                "The bus is a cheap alternative to taxis.",
                "She considered several alternatives before deciding."
            ],
            level: .b2, topics: [.general]
        ),
        CommonWord(
            term: "amateur",
            partOfSpeech: "noun",
            ipa: "/ˈæmətə/",
            countability: "countable",
            definition: "Someone who is inexperienced or not highly skilled.",
            turkishMeaning: "amatör",
            examples: [
                "He's an amateur soccer player and is still learning the rules of the game.",
                "She paints as an amateur.",
                "Don't worry — I'm a complete amateur.",
                "Amateurs sometimes outperform professionals.",
                "The competition is open to amateurs."
            ],
            level: .b2, topics: [.general]
        ),
        CommonWord(
            term: "ambiguous",
            partOfSpeech: "adjective",
            ipa: "/æmˈbɪɡjuəs/",
            countability: "N/A",
            definition: "Having several potential meanings; unclear.",
            turkishMeaning: "belirsiz, muğlak",
            examples: [
                "When I asked the HR manager what my chances were, she gave me a very ambiguous reply.",
                "The instructions were too ambiguous to follow.",
                "He made an ambiguous statement to avoid commitment.",
                "Their relationship status is ambiguous.",
                "Please rewrite that ambiguous sentence."
            ],
            level: .c1, topics: [.academic]
        ),
        CommonWord(
            term: "ambitious",
            partOfSpeech: "adjective",
            ipa: "/æmˈbɪʃəs/",
            countability: "N/A",
            definition: "Having strong desire for success or achievement.",
            turkishMeaning: "hırslı, tutkulu",
            examples: [
                "My son is very ambitious and hopes to be a millionaire by the time he's thirty.",
                "It's an ambitious plan but achievable.",
                "She is ambitious and works very hard.",
                "Their goals are ambitious but realistic.",
                "He set himself ambitious targets for the year."
            ],
            level: .b2, topics: [.work, .emotions]
        ),
        CommonWord(
            term: "amend",
            partOfSpeech: "verb",
            ipa: "/əˈmɛnd/",
            countability: "N/A",
            definition: "To change for the better; to improve a text or law.",
            turkishMeaning: "değiştirmek, düzeltmek",
            examples: [
                "I believe we should amend our country's tax laws.",
                "The contract was amended last week.",
                "They amended their plans after the meeting.",
                "Congress voted to amend the bill.",
                "She amended her report after receiving feedback."
            ],
            level: .c1, topics: [.business, .academic]
        ),
        CommonWord(
            term: "ample",
            partOfSpeech: "adjective",
            ipa: "/ˈæmpl/",
            countability: "N/A",
            definition: "Plentiful; more than enough.",
            turkishMeaning: "bol, geniş",
            examples: [
                "Our new apartment has ample space for the two of us.",
                "There was ample time to finish the test.",
                "We have ample evidence to support the claim.",
                "The hotel provided ample food and drink.",
                "She received ample compensation for the damages."
            ],
            level: .c1, topics: [.general]
        ),
        CommonWord(
            term: "anomaly",
            partOfSpeech: "noun",
            ipa: "/əˈnɒməli/",
            countability: "countable",
            definition: "Something that deviates from the norm.",
            turkishMeaning: "anomali, aykırılık",
            examples: [
                "The basketball player missing both free throws was an anomaly.",
                "Scientists are studying the temperature anomaly.",
                "This data point is an anomaly in our results.",
                "The system flagged the transaction as an anomaly.",
                "Her behavior was an anomaly that day."
            ],
            level: .c1, topics: [.academic]
        ),
        CommonWord(
            term: "annual",
            partOfSpeech: "adjective",
            ipa: "/ˈænjʊəl/",
            countability: "N/A",
            definition: "Occurring once every year.",
            turkishMeaning: "yıllık",
            examples: [
                "The annual company barbeque takes place every August.",
                "We attend the annual conference each spring.",
                "The annual report was published yesterday.",
                "She earns a good annual salary.",
                "The annual festival attracts thousands of visitors."
            ],
            level: .b2, topics: [.business, .general]
        ),
        CommonWord(
            term: "antagonize",
            partOfSpeech: "verb",
            ipa: "/ænˈtæɡənaɪz/",
            countability: "N/A",
            definition: "To tease or be hostile towards someone.",
            turkishMeaning: "düşmanca davranmak, kızdırmak",
            examples: [
                "The boy loves to antagonize his little sister by pulling her hair.",
                "Don't antagonize him — he's already upset.",
                "Her comments only antagonized the audience.",
                "The policy antagonized many citizens.",
                "Try not to antagonize your boss."
            ],
            level: .c2, topics: [.emotions]
        ),
        CommonWord(
            term: "attitude",
            partOfSpeech: "noun",
            ipa: "/ˈætɪtjuːd/",
            countability: "countable",
            definition: "A way of thinking, feeling, or behaving.",
            turkishMeaning: "tutum, tavır",
            examples: [
                "After she got grounded, the teenager had a bad attitude for the rest of the day.",
                "He has a positive attitude towards work.",
                "Her attitude has changed since college.",
                "A good attitude is essential for success.",
                "Their attitude towards us was friendly."
            ],
            level: .b2, topics: [.emotions, .general]
        ),
        CommonWord(
            term: "attribute",
            partOfSpeech: "verb",
            ipa: "/əˈtrɪbjuːt/",
            countability: "N/A",
            definition: "To give credit; to consider something as caused by.",
            turkishMeaning: "atfetmek, bağlamak",
            examples: [
                "Be sure to attribute credit to your sources when writing a research paper.",
                "He attributes his success to hard work.",
                "The painting is attributed to Picasso.",
                "She attributed her health to good genes.",
                "Many problems are attributed to lack of sleep."
            ],
            level: .c1, topics: [.academic]
        ),
        CommonWord(
            term: "arbitrary",
            partOfSpeech: "adjective",
            ipa: "/ˈɑːbɪtrəri/",
            countability: "N/A",
            definition: "Based on a whim or random decision rather than reason.",
            turkishMeaning: "keyfi, rastgele",
            examples: [
                "Flipping a coin is an arbitrary way to make a decision.",
                "The rules seem arbitrary and unfair.",
                "The deadline was set in an arbitrary manner.",
                "He made an arbitrary choice of color.",
                "The judge's ruling appeared arbitrary."
            ],
            level: .c1, topics: [.academic]
        ),
        CommonWord(
            term: "arduous",
            partOfSpeech: "adjective",
            ipa: "/ˈɑːdjʊəs/",
            countability: "N/A",
            definition: "Requiring a lot of effort; difficult and tiring.",
            turkishMeaning: "zorlu, çetin",
            examples: [
                "After you cross the bridge, there's an arduous walk up the hill.",
                "Becoming a doctor is an arduous journey.",
                "The project proved more arduous than expected.",
                "It was an arduous climb to the summit.",
                "Negotiations were long and arduous."
            ],
            level: .c2, topics: [.general]
        ),
        CommonWord(
            term: "assuage",
            partOfSpeech: "verb",
            ipa: "/əˈsweɪdʒ/",
            countability: "N/A",
            definition: "To lessen a negative feeling such as pain or fear.",
            turkishMeaning: "yatıştırmak, hafifletmek",
            examples: [
                "The mother assuaged her child's fear of the dark.",
                "His words did little to assuage my worries.",
                "The medication assuaged the pain.",
                "Nothing could assuage her grief.",
                "He tried to assuage their concerns."
            ],
            level: .c2, topics: [.emotions]
        ),
        CommonWord(
            term: "assume",
            partOfSpeech: "verb",
            ipa: "/əˈsjuːm/",
            countability: "N/A",
            definition: "To suppose something without solid proof.",
            turkishMeaning: "varsaymak, sanmak",
            examples: [
                "I assumed he was rich because he worked as a lawyer.",
                "Don't assume what people are thinking.",
                "She assumed responsibility for the project.",
                "Let's assume the data is correct.",
                "I assume you've already eaten."
            ],
            level: .b2, topics: [.general]
        ),
        CommonWord(
            term: "augment",
            partOfSpeech: "verb",
            ipa: "/ɔːɡˈmɛnt/",
            countability: "N/A",
            definition: "To increase or make larger.",
            turkishMeaning: "artırmak, çoğaltmak",
            examples: [
                "She augments her regular salary by babysitting on the weekends.",
                "The lecture was augmented with slides.",
                "They augmented the workforce with temporary staff.",
                "Technology can augment human abilities.",
                "He augmented his savings through investments."
            ],
            level: .c2, topics: [.academic, .business]
        ),
        CommonWord(
            term: "berate",
            partOfSpeech: "verb",
            ipa: "/bɪˈreɪt/",
            countability: "N/A",
            definition: "To scold or criticize angrily.",
            turkishMeaning: "azarlamak, paylamak",
            examples: [
                "Our neighbor berated us after we broke his window playing baseball.",
                "The coach berated the team for poor play.",
                "She berated him for being late.",
                "He berated himself for the mistake.",
                "Don't berate the children publicly."
            ],
            level: .c2, topics: [.emotions]
        ),
        CommonWord(
            term: "bestow",
            partOfSpeech: "verb",
            ipa: "/bɪˈstəʊ/",
            countability: "N/A",
            definition: "To give as a gift or honor.",
            turkishMeaning: "vermek, bahşetmek",
            examples: [
                "The medal was bestowed upon him by the president.",
                "An honorary degree was bestowed on the scientist.",
                "She bestowed a kiss on his cheek.",
                "Knighthood is bestowed by the queen.",
                "He bestowed his fortune on charity."
            ],
            level: .c2, topics: [.general]
        ),
        CommonWord(
            term: "boast",
            partOfSpeech: "verb",
            ipa: "/bəʊst/",
            countability: "N/A",
            definition: "To brag or talk with excessive pride.",
            turkishMeaning: "övünmek, böbürlenmek",
            examples: [
                "He always boasts of his talents after he wins a game.",
                "She doesn't like to boast about her achievements.",
                "They boasted that their team would win.",
                "Don't boast — it's not attractive.",
                "The hotel boasts a swimming pool and gym."
            ],
            level: .c1, topics: [.emotions]
        ),
        CommonWord(
            term: "boost",
            partOfSpeech: "verb",
            ipa: "/buːst/",
            countability: "N/A",
            definition: "To help raise or increase something.",
            turkishMeaning: "artırmak, yükseltmek",
            examples: [
                "I gave him a pep talk to boost his self-esteem before his speech.",
                "The new ads boosted sales.",
                "Exercise can boost your mood.",
                "Coffee gave me a much-needed boost.",
                "She boosted the team's morale with kind words."
            ],
            level: .b2, topics: [.business]
        ),
        CommonWord(
            term: "brash",
            partOfSpeech: "adjective",
            ipa: "/bræʃ/",
            countability: "N/A",
            definition: "Rude, tactless, or overly confident.",
            turkishMeaning: "küstah, kaba",
            examples: [
                "The brash man always asked inappropriate questions.",
                "His brash manner offended several guests.",
                "She gave a brash, confident answer.",
                "The brash newcomer challenged the boss.",
                "He's young and brash but talented."
            ],
            level: .c2, topics: [.emotions]
        ),
        CommonWord(
            term: "brief",
            partOfSpeech: "adjective",
            ipa: "/briːf/",
            countability: "N/A",
            definition: "Short in time or duration.",
            turkishMeaning: "kısa, öz",
            examples: [
                "It will only be a brief meeting, so you'll still have plenty of time for lunch.",
                "She gave a brief explanation of the rules.",
                "His visit was brief but pleasant.",
                "Please be brief — we don't have much time.",
                "There was a brief silence before he replied."
            ],
            level: .b2, topics: [.general, .work]
        ),
        CommonWord(
            term: "brusque",
            partOfSpeech: "adjective",
            ipa: "/bruːsk/",
            countability: "N/A",
            definition: "Abrupt to the point of rudeness.",
            turkishMeaning: "kaba, sert",
            examples: [
                "After being away for so long, I expected more than her brusque greeting.",
                "His brusque tone surprised everyone.",
                "She gave a brusque reply and walked away.",
                "The manager was brusque with the new employees.",
                "Don't be brusque with customers."
            ],
            level: .c2, topics: [.emotions]
        ),
        CommonWord(
            term: "cacophony",
            partOfSpeech: "noun",
            ipa: "/kəˈkɒfəni/",
            countability: "countable",
            definition: "A harsh, unpleasant mixture of noise.",
            turkishMeaning: "uyumsuz ses, gürültü",
            examples: [
                "The cuckoo clock shop lets off a cacophony every hour.",
                "A cacophony of car horns filled the street.",
                "The orchestra warmed up in a cacophony of sound.",
                "We were greeted by a cacophony of barking dogs.",
                "There was a cacophony of voices in the room."
            ],
            level: .c2, topics: [.general]
        ),
        CommonWord(
            term: "cease",
            partOfSpeech: "verb",
            ipa: "/siːs/",
            countability: "N/A",
            definition: "To stop or come to an end.",
            turkishMeaning: "durmak, son vermek",
            examples: [
                "I wish they would cease arguing.",
                "The factory ceased operations last year.",
                "He never ceases to amaze me.",
                "The rain finally ceased.",
                "Please cease this behavior immediately."
            ],
            level: .c1, topics: [.general]
        ),
        CommonWord(
            term: "censure",
            partOfSpeech: "verb",
            ipa: "/ˈsɛnʃə/",
            countability: "N/A",
            definition: "To express strong disapproval, often formally.",
            turkishMeaning: "kınamak, ayıplamak",
            examples: [
                "Every parent in our district censured the education cuts.",
                "The senator was censured for misconduct.",
                "Critics censured the film for being too violent.",
                "He was publicly censured by his colleagues.",
                "The board voted to censure the chairman."
            ],
            level: .c2, topics: [.business]
        ),
        CommonWord(
            term: "chronological",
            partOfSpeech: "adjective",
            ipa: "/ˌkrɒnəˈlɒdʒɪkl/",
            countability: "N/A",
            definition: "Arranged in order of time or date.",
            turkishMeaning: "kronolojik",
            examples: [
                "Put the historical events in chronological order to make them easier to study.",
                "Please list your work experience in chronological order.",
                "The book follows a chronological structure.",
                "Photos are organized in chronological sequence.",
                "Her diary is a chronological record of her life."
            ],
            level: .c1, topics: [.academic]
        ),
        CommonWord(
            term: "clarify",
            partOfSpeech: "verb",
            ipa: "/ˈklærɪfaɪ/",
            countability: "N/A",
            definition: "To make clear; to remove confusion.",
            turkishMeaning: "açıklığa kavuşturmak, netleştirmek",
            examples: [
                "I didn't understand the instructions, so I asked the teacher to clarify them.",
                "Can you clarify your last point?",
                "She clarified her position on the issue.",
                "Let me clarify what I meant.",
                "We need to clarify the rules before starting."
            ],
            level: .b2, topics: [.academic, .work]
        ),
        CommonWord(
            term: "coalesce",
            partOfSpeech: "verb",
            ipa: "/ˌkəʊəˈlɛs/",
            countability: "N/A",
            definition: "To combine or grow together to form one.",
            turkishMeaning: "birleşmek, kaynaşmak",
            examples: [
                "The people on the street eventually coalesced into a group.",
                "Several small groups coalesced into a movement.",
                "Their ideas coalesced into a single plan.",
                "Droplets of water coalesced on the window.",
                "The opposition coalesced around one candidate."
            ],
            level: .c2, topics: [.academic]
        ),
        CommonWord(
            term: "coerce",
            partOfSpeech: "verb",
            ipa: "/kəʊˈɜːs/",
            countability: "N/A",
            definition: "To force someone to do something against their will.",
            turkishMeaning: "zorlamak, baskı yapmak",
            examples: [
                "The young boy was coerced into stealing by his friends.",
                "She felt coerced into signing the contract.",
                "They tried to coerce him into confessing.",
                "No one should be coerced into a decision.",
                "He was coerced through threats."
            ],
            level: .c1, topics: [.general]
        ),
        CommonWord(
            term: "cognizant",
            partOfSpeech: "adjective",
            ipa: "/ˈkɒɡnɪzənt/",
            countability: "N/A",
            definition: "Being aware or having knowledge of something.",
            turkishMeaning: "farkında, haberdar",
            examples: [
                "Before mountain climbing, you need to be cognizant of the risks.",
                "She is cognizant of her responsibilities.",
                "We must be cognizant of cultural differences.",
                "He is fully cognizant of the consequences.",
                "Be cognizant of your surroundings."
            ],
            level: .c2, topics: [.academic]
        ),
        CommonWord(
            term: "cohesion",
            partOfSpeech: "noun",
            ipa: "/kəʊˈhiːʒn/",
            countability: "uncountable",
            definition: "The act of uniting or sticking together.",
            turkishMeaning: "bütünlük, uyum",
            examples: [
                "Water molecules show strong cohesion when they stick together.",
                "Team cohesion is critical for success.",
                "Social cohesion has weakened in recent years.",
                "The essay lacks cohesion between paragraphs.",
                "Strong cohesion makes a community resilient."
            ],
            level: .c1, topics: [.academic]
        ),
        CommonWord(
            term: "coincide",
            partOfSpeech: "verb",
            ipa: "/ˌkəʊɪnˈsaɪd/",
            countability: "N/A",
            definition: "To occur at the same time as something else.",
            turkishMeaning: "aynı zamana denk gelmek",
            examples: [
                "This year Thanksgiving coincided with my birthday.",
                "Our visit coincided with the festival.",
                "Their interests rarely coincide.",
                "The two events happened to coincide.",
                "His arrival coincided with the storm."
            ],
            level: .c1, topics: [.general]
        ),
        CommonWord(
            term: "collapse",
            partOfSpeech: "verb",
            ipa: "/kəˈlæps/",
            countability: "N/A",
            definition: "To fall down or break down suddenly.",
            turkishMeaning: "çökmek, yıkılmak",
            examples: [
                "The old building finally collapsed, leaving nothing but a pile of rubble.",
                "He collapsed from exhaustion.",
                "The bridge collapsed during the earthquake.",
                "The negotiations collapsed at the last minute.",
                "Her business collapsed during the recession."
            ],
            level: .b2, topics: [.general]
        ),
        CommonWord(
            term: "collide",
            partOfSpeech: "verb",
            ipa: "/kəˈlaɪd/",
            countability: "N/A",
            definition: "To hit one another with a forceful impact.",
            turkishMeaning: "çarpışmak",
            examples: [
                "The two cars collided on the freeway.",
                "The cyclists collided at the intersection.",
                "Their opinions often collide.",
                "Two galaxies will eventually collide.",
                "He collided with the wall while running."
            ],
            level: .b2, topics: [.general]
        ),
        CommonWord(
            term: "commitment",
            partOfSpeech: "noun",
            ipa: "/kəˈmɪtmənt/",
            countability: "both",
            definition: "Dedication to a cause or activity.",
            turkishMeaning: "bağlılık, taahhüt",
            examples: [
                "Joining a school play is a big commitment.",
                "He showed great commitment to his studies.",
                "Marriage is a lifelong commitment.",
                "We need a commitment from both parties.",
                "Her commitment to charity is inspiring."
            ],
            level: .b2, topics: [.work, .emotions]
        ),
        CommonWord(
            term: "community",
            partOfSpeech: "noun",
            ipa: "/kəˈmjuːnəti/",
            countability: "countable",
            definition: "A group of people living or working together.",
            turkishMeaning: "topluluk, cemiyet",
            examples: [
                "The Chinese community in my city is hosting a New Year celebration next week.",
                "She is active in her local community.",
                "The community came together after the storm.",
                "Online communities support many hobbies.",
                "He moved to a small farming community."
            ],
            level: .b2, topics: [.daily]
        ),
        CommonWord(
            term: "conceal",
            partOfSpeech: "verb",
            ipa: "/kənˈsiːl/",
            countability: "N/A",
            definition: "To hide or keep secret.",
            turkishMeaning: "gizlemek, saklamak",
            examples: [
                "The mountains concealed the ocean from view.",
                "She tried to conceal her disappointment.",
                "He concealed the gift behind his back.",
                "The truth could not be concealed forever.",
                "Makeup can conceal blemishes."
            ],
            level: .c1, topics: [.general]
        ),
        CommonWord(
            term: "concur",
            partOfSpeech: "verb",
            ipa: "/kənˈkɜː/",
            countability: "N/A",
            definition: "To agree with someone or something.",
            turkishMeaning: "katılmak, mutabık olmak",
            examples: [
                "He believes women should be paid as much as men, and I concur.",
                "The experts concur on the diagnosis.",
                "I concur with your assessment.",
                "Most scientists concur on the cause.",
                "She did not concur with the verdict."
            ],
            level: .c2, topics: [.academic]
        ),
        CommonWord(
            term: "conflict",
            partOfSpeech: "noun",
            ipa: "/ˈkɒnflɪkt/",
            countability: "countable",
            definition: "A disagreement or fight.",
            turkishMeaning: "çatışma, anlaşmazlık",
            examples: [
                "The conflict between the two families has been going on for generations.",
                "There is a conflict of interest here.",
                "The country is in a state of conflict.",
                "We need to resolve this conflict quickly.",
                "Conflicts in the workplace are common."
            ],
            level: .b2, topics: [.emotions, .general]
        ),
        CommonWord(
            term: "constrain",
            partOfSpeech: "verb",
            ipa: "/kənˈstreɪn/",
            countability: "N/A",
            definition: "To restrict or limit something.",
            turkishMeaning: "kısıtlamak, sınırlamak",
            examples: [
                "You should move your plant to a bigger pot, otherwise you'll constrain its roots.",
                "Budget cuts constrain our options.",
                "She felt constrained by tradition.",
                "Time constraints made the task difficult.",
                "Don't let fear constrain your dreams."
            ],
            level: .c1, topics: [.academic]
        ),
        CommonWord(
            term: "contemplate",
            partOfSpeech: "verb",
            ipa: "/ˈkɒntəmpleɪt/",
            countability: "N/A",
            definition: "To consider thoughtfully.",
            turkishMeaning: "düşünmek, tefekkür etmek",
            examples: [
                "I spend a lot of time contemplating what career I want to have.",
                "She contemplated the painting silently.",
                "He's contemplating a move to Berlin.",
                "Let's contemplate our options carefully.",
                "I never contemplated giving up."
            ],
            level: .c1, topics: [.emotions]
        ),
        CommonWord(
            term: "continuously",
            partOfSpeech: "adverb",
            ipa: "/kənˈtɪnjuəsli/",
            countability: "N/A",
            definition: "Without stopping or interruption.",
            turkishMeaning: "sürekli, aralıksız",
            examples: [
                "My neighbors have been continuously blasting their music since last night.",
                "The machine runs continuously for 24 hours.",
                "He worked continuously without a break.",
                "Prices have risen continuously this year.",
                "She talked continuously throughout the trip."
            ],
            level: .b2, topics: [.general]
        ),
        CommonWord(
            term: "contradict",
            partOfSpeech: "verb",
            ipa: "/ˌkɒntrəˈdɪkt/",
            countability: "N/A",
            definition: "To give or assert the opposite opinion.",
            turkishMeaning: "çelişmek, yalanlamak",
            examples: [
                "I told the employees sales were down, but my boss contradicted me.",
                "His actions contradict his words.",
                "She didn't dare contradict her father.",
                "The new evidence contradicts the theory.",
                "The two reports contradict each other."
            ],
            level: .c1, topics: [.academic]
        ),
        CommonWord(
            term: "contribute",
            partOfSpeech: "verb",
            ipa: "/kənˈtrɪbjuːt/",
            countability: "N/A",
            definition: "To give something (money, time, ideas) to a common cause.",
            turkishMeaning: "katkıda bulunmak",
            examples: [
                "Every roommate contributes part of his paycheck to the grocery bill.",
                "She contributed to the discussion.",
                "Many factors contributed to his success.",
                "We all contributed to the project.",
                "He contributes articles to the magazine."
            ],
            level: .b2, topics: [.work, .academic]
        ),
        CommonWord(
            term: "convey",
            partOfSpeech: "verb",
            ipa: "/kənˈveɪ/",
            countability: "N/A",
            definition: "To make known; to communicate.",
            turkishMeaning: "iletmek, aktarmak",
            examples: [
                "I've conveyed my interest in working for that company.",
                "Please convey my thanks to your parents.",
                "Words cannot convey how I feel.",
                "The painting conveys deep emotion.",
                "She conveyed the message accurately."
            ],
            level: .c1, topics: [.general]
        ),
        CommonWord(
            term: "copious",
            partOfSpeech: "adjective",
            ipa: "/ˈkəʊpiəs/",
            countability: "N/A",
            definition: "Abundant; existing in large quantities.",
            turkishMeaning: "bol, çok",
            examples: [
                "He always takes copious notes during class to study later on.",
                "She drank copious amounts of water.",
                "The book has copious illustrations.",
                "We received copious feedback on the proposal.",
                "Copious rainfall flooded the streets."
            ],
            level: .c2, topics: [.academic]
        ),
        CommonWord(
            term: "core",
            partOfSpeech: "adjective",
            ipa: "/kɔː/",
            countability: "N/A",
            definition: "Central; of main importance.",
            turkishMeaning: "esas, çekirdek",
            examples: [
                "Although many employees left, the core leadership remained.",
                "The core values of the company are integrity and honesty.",
                "Reading is a core skill in school.",
                "Our core business is software development.",
                "He works on the core team."
            ],
            level: .b2, topics: [.business]
        ),
        CommonWord(
            term: "corrode",
            partOfSpeech: "verb",
            ipa: "/kəˈrəʊd/",
            countability: "N/A",
            definition: "To gradually wear away, especially by chemical action.",
            turkishMeaning: "aşındırmak, paslandırmak",
            examples: [
                "The rust corroded the paint on my car.",
                "Salt water corrodes metal quickly.",
                "Acid rain corrodes statues.",
                "Distrust can corrode any relationship.",
                "The pipes had corroded over time."
            ],
            level: .c1, topics: [.nature]
        ),
        CommonWord(
            term: "cumbersome",
            partOfSpeech: "adjective",
            ipa: "/ˈkʌmbəsəm/",
            countability: "N/A",
            definition: "Burdensome; difficult to carry or use.",
            turkishMeaning: "hantal, kullanışsız",
            examples: [
                "Trying to carry four grocery bags at once was very cumbersome.",
                "The process is cumbersome and slow.",
                "Old laptops were cumbersome to travel with.",
                "Their cumbersome rules slow us down.",
                "It's a cumbersome but necessary procedure."
            ],
            level: .c2, topics: [.general]
        ),
        CommonWord(
            term: "curriculum",
            partOfSpeech: "noun",
            ipa: "/kəˈrɪkjələm/",
            countability: "countable",
            definition: "The courses given by a school or program.",
            turkishMeaning: "müfredat",
            examples: [
                "Our school needs to add more music courses to its curriculum.",
                "The new curriculum focuses on STEM subjects.",
                "She helped design the curriculum.",
                "Foreign languages are part of the curriculum.",
                "The curriculum will be revised next year."
            ],
            level: .c1, topics: [.academic]
        ),
        CommonWord(
            term: "data",
            partOfSpeech: "noun",
            ipa: "/ˈdeɪtə/",
            countability: "uncountable",
            definition: "Facts, statistics, or pieces of information.",
            turkishMeaning: "veri, bilgi",
            examples: [
                "The data from these graphs show that yearly temperatures are increasing.",
                "We collected data from 500 participants.",
                "All the data is stored securely.",
                "The data suggests a clear trend.",
                "He analyzed the data carefully."
            ],
            level: .b2, topics: [.academic, .technology]
        ),
        CommonWord(
            term: "decay",
            partOfSpeech: "verb",
            ipa: "/dɪˈkeɪ/",
            countability: "N/A",
            definition: "To decline in health, quality, or condition.",
            turkishMeaning: "çürümek, bozulmak",
            examples: [
                "After the tree died, its wood began to decay.",
                "Sugar can cause teeth to decay.",
                "The old empire slowly decayed.",
                "Fruit will decay quickly without refrigeration.",
                "Their morale began to decay."
            ],
            level: .c1, topics: [.nature]
        ),
        CommonWord(
            term: "deceive",
            partOfSpeech: "verb",
            ipa: "/dɪˈsiːv/",
            countability: "N/A",
            definition: "To trick or mislead someone.",
            turkishMeaning: "aldatmak, kandırmak",
            examples: [
                "He deceived me by pretending to be a millionaire.",
                "She would never deceive her friends.",
                "The advertisement deceived many customers.",
                "Don't deceive yourself about the risks.",
                "He was deceived by a clever scam."
            ],
            level: .c1, topics: [.general]
        ),
        CommonWord(
            term: "decipher",
            partOfSpeech: "verb",
            ipa: "/dɪˈsaɪfə/",
            countability: "N/A",
            definition: "To find the meaning of something hard to understand.",
            turkishMeaning: "çözmek, deşifre etmek",
            examples: [
                "The spy deciphered the secret code.",
                "I can't decipher his handwriting.",
                "Scholars deciphered the ancient text.",
                "She tried to decipher his expression.",
                "It took hours to decipher the message."
            ],
            level: .c2, topics: [.academic]
        ),
        CommonWord(
            term: "declaration",
            partOfSpeech: "noun",
            ipa: "/ˌdɛkləˈreɪʃn/",
            countability: "countable",
            definition: "A formal announcement.",
            turkishMeaning: "bildiri, beyanname",
            examples: [
                "He made a declaration to the office that he was quitting.",
                "The Declaration of Independence is famous.",
                "She signed a customs declaration at the airport.",
                "Their declaration of love was sincere.",
                "The president issued a declaration of war."
            ],
            level: .c1, topics: [.business]
        ),
        CommonWord(
            term: "decline",
            partOfSpeech: "verb",
            ipa: "/dɪˈklaɪn/",
            countability: "N/A",
            definition: "To politely refuse, or to decrease in quality or strength.",
            turkishMeaning: "reddetmek, azalmak",
            examples: [
                "I declined his offer of a ride home.",
                "Her health has declined ever since she turned 70.",
                "Sales declined last quarter.",
                "He declined the invitation politely.",
                "The empire declined over centuries."
            ],
            level: .b2, topics: [.business, .health]
        ),
        CommonWord(
            term: "degrade",
            partOfSpeech: "verb",
            ipa: "/dɪˈɡreɪd/",
            countability: "N/A",
            definition: "To lower in quality or value.",
            turkishMeaning: "alçaltmak, bozmak",
            examples: [
                "My attempt at cake degraded into a crumbly mess.",
                "Pollution degrades the environment.",
                "Don't degrade yourself by lying.",
                "The image quality has degraded over time.",
                "Plastic does not easily degrade."
            ],
            level: .c1, topics: [.nature]
        ),
        CommonWord(
            term: "demonstrate",
            partOfSpeech: "verb",
            ipa: "/ˈdɛmənstreɪt/",
            countability: "N/A",
            definition: "To clearly show or explain something.",
            turkishMeaning: "göstermek, kanıtlamak",
            examples: [
                "Let me demonstrate the proper way of throwing a football.",
                "The results demonstrate clear progress.",
                "She demonstrated how the machine works.",
                "He demonstrated great leadership skills.",
                "Studies demonstrate that exercise helps mood."
            ],
            level: .b2, topics: [.academic]
        ),
        CommonWord(
            term: "deny",
            partOfSpeech: "verb",
            ipa: "/dɪˈnaɪ/",
            countability: "N/A",
            definition: "To state that something is not true.",
            turkishMeaning: "inkâr etmek, reddetmek",
            examples: [
                "He denied being the robber.",
                "She denied any involvement in the scandal.",
                "You can't deny the facts.",
                "His request was denied by the manager.",
                "I won't deny that I was nervous."
            ],
            level: .b2, topics: [.general]
        ),
        CommonWord(
            term: "deplete",
            partOfSpeech: "verb",
            ipa: "/dɪˈpliːt/",
            countability: "N/A",
            definition: "To significantly decrease or use up.",
            turkishMeaning: "tüketmek, azaltmak",
            examples: [
                "Your shopping sprees have depleted my savings.",
                "Mining depletes natural resources.",
                "The hike depleted my energy.",
                "Stress can deplete vitamin levels.",
                "Their food supplies were depleted."
            ],
            level: .c1, topics: [.nature]
        ),
        CommonWord(
            term: "deposit",
            partOfSpeech: "verb",
            ipa: "/dɪˈpɒzɪt/",
            countability: "N/A",
            definition: "To deliver and leave an item, often money.",
            turkishMeaning: "yatırmak, bırakmak",
            examples: [
                "Please deposit your books in the bin outside the library.",
                "I deposited my paycheck into the bank.",
                "The river deposits sediment along its banks.",
                "She deposited the keys on the table.",
                "You can deposit cash at the ATM."
            ],
            level: .b2, topics: [.business]
        ),
        CommonWord(
            term: "desirable",
            partOfSpeech: "adjective",
            ipa: "/dɪˈzaɪərəbl/",
            countability: "N/A",
            definition: "Worth having or wanting.",
            turkishMeaning: "arzu edilen, istenen",
            examples: [
                "Bravery is a desirable trait for firefighters to have.",
                "It's desirable to know more than one language.",
                "This neighborhood is highly desirable.",
                "The job has many desirable benefits.",
                "Honesty is a desirable quality."
            ],
            level: .c1, topics: [.general]
        ),
        CommonWord(
            term: "despise",
            partOfSpeech: "verb",
            ipa: "/dɪˈspaɪz/",
            countability: "N/A",
            definition: "To hate or strongly dislike.",
            turkishMeaning: "tiksinmek, hor görmek",
            examples: [
                "I despise early morning classes.",
                "She despises liars.",
                "He despised his cruel boss.",
                "Many people despise injustice.",
                "I despise being interrupted."
            ],
            level: .c1, topics: [.emotions]
        ),
        CommonWord(
            term: "detect",
            partOfSpeech: "verb",
            ipa: "/dɪˈtɛkt/",
            countability: "N/A",
            definition: "To discover or locate something.",
            turkishMeaning: "saptamak, tespit etmek",
            examples: [
                "The police dog detected the missing child's scent.",
                "Sensors can detect motion.",
                "She detected a hint of sarcasm.",
                "The disease was detected early.",
                "Cameras detected the intruder."
            ],
            level: .b2, topics: [.technology]
        ),
        CommonWord(
            term: "deter",
            partOfSpeech: "verb",
            ipa: "/dɪˈtɜː/",
            countability: "N/A",
            definition: "To discourage someone from doing something.",
            turkishMeaning: "caydırmak, vazgeçirmek",
            examples: [
                "The warning signs on the house deterred trespassers.",
                "Heavy fines deter speeding.",
                "Don't let failure deter you.",
                "Cold weather deters tourists.",
                "Locks deter thieves."
            ],
            level: .c1, topics: [.general]
        ),
        CommonWord(
            term: "deviate",
            partOfSpeech: "verb",
            ipa: "/ˈdiːvieɪt/",
            countability: "N/A",
            definition: "To differ from the norm or expected path.",
            turkishMeaning: "sapmak, ayrılmak",
            examples: [
                "I decided to deviate from my normal route home and took a shortcut.",
                "Don't deviate from the plan.",
                "The data deviates from previous studies.",
                "She rarely deviates from her routine.",
                "His behavior deviated from expectations."
            ],
            level: .c1, topics: [.academic]
        ),
        CommonWord(
            term: "devise",
            partOfSpeech: "verb",
            ipa: "/dɪˈvaɪz/",
            countability: "N/A",
            definition: "To plan or create, especially something complex.",
            turkishMeaning: "tasarlamak, planlamak",
            examples: [
                "The coach devised a plan for winning the game.",
                "She devised a clever puzzle.",
                "They devised a strategy to cut costs.",
                "He devised a new method of testing.",
                "We must devise a solution quickly."
            ],
            level: .c1, topics: [.academic]
        ),
        CommonWord(
            term: "diatribe",
            partOfSpeech: "noun",
            ipa: "/ˈdaɪətraɪb/",
            countability: "countable",
            definition: "A sharp criticism or verbal attack.",
            turkishMeaning: "sert eleştiri, hicvetme",
            examples: [
                "The politician went into a diatribe against her opponent.",
                "His diatribe on social media went viral.",
                "She delivered a diatribe about traffic.",
                "I had to listen to a long diatribe.",
                "The article was a diatribe against modern art."
            ],
            level: .c2, topics: [.academic]
        ),
        CommonWord(
            term: "digress",
            partOfSpeech: "verb",
            ipa: "/daɪˈɡrɛs/",
            countability: "N/A",
            definition: "To wander from the main subject.",
            turkishMeaning: "konudan sapmak",
            examples: [
                "The teacher digressed from the lecture to discuss the weather.",
                "Sorry, I'm digressing — back to the topic.",
                "He tends to digress when speaking.",
                "She digressed briefly into a personal story.",
                "Try not to digress during the presentation."
            ],
            level: .c2, topics: [.academic]
        ),
        CommonWord(
            term: "dilemma",
            partOfSpeech: "noun",
            ipa: "/dɪˈlɛmə/",
            countability: "countable",
            definition: "A situation requiring a choice between difficult options.",
            turkishMeaning: "ikilem, çıkmaz",
            examples: [
                "The student faced the dilemma of attending school sick or missing her exam.",
                "I'm in a moral dilemma.",
                "It's a difficult dilemma to resolve.",
                "She faced an ethical dilemma at work.",
                "Their dilemma was solved by compromise."
            ],
            level: .c1, topics: [.general]
        ),
        CommonWord(
            term: "diminish",
            partOfSpeech: "verb",
            ipa: "/dɪˈmɪnɪʃ/",
            countability: "N/A",
            definition: "To shrink, reduce, or become less.",
            turkishMeaning: "azaltmak, küçültmek",
            examples: [
                "Sprinkle baking soda on the carpet to diminish the stain.",
                "Her interest diminished over time.",
                "Don't diminish his achievements.",
                "Light diminished as the sun set.",
                "Resources are quickly diminishing."
            ],
            level: .c1, topics: [.general]
        ),
        CommonWord(
            term: "dispose",
            partOfSpeech: "verb",
            ipa: "/dɪˈspəʊz/",
            countability: "N/A",
            definition: "To get rid of something.",
            turkishMeaning: "atmak, elden çıkarmak",
            examples: [
                "I need to dispose of this trash.",
                "Please dispose of batteries properly.",
                "How should we dispose of old electronics?",
                "Hospitals dispose of waste safely.",
                "He disposed of all his old books."
            ],
            level: .b2, topics: [.daily]
        ),
        CommonWord(
            term: "disproportionate",
            partOfSpeech: "adjective",
            ipa: "/ˌdɪsprəˈpɔːʃənət/",
            countability: "N/A",
            definition: "Too large or small in comparison to something else.",
            turkishMeaning: "orantısız",
            examples: [
                "The piece of pie I received was disproportionately small.",
                "The punishment was disproportionate to the crime.",
                "He spends a disproportionate amount on coffee.",
                "Their response was disproportionate.",
                "She has a disproportionate influence on policy."
            ],
            level: .c1, topics: [.academic]
        ),
        CommonWord(
            term: "disrupt",
            partOfSpeech: "verb",
            ipa: "/dɪsˈrʌpt/",
            countability: "N/A",
            definition: "To interrupt by causing a disturbance.",
            turkishMeaning: "aksatmak, bozmak",
            examples: [
                "The protesters disrupted the politician's speech.",
                "Snowstorms disrupted travel plans.",
                "Don't disrupt the class.",
                "The new technology disrupted the industry.",
                "Construction noise disrupted our meeting."
            ],
            level: .c1, topics: [.business]
        ),
        CommonWord(
            term: "distort",
            partOfSpeech: "verb",
            ipa: "/dɪsˈtɔːt/",
            countability: "N/A",
            definition: "To misrepresent or twist out of shape.",
            turkishMeaning: "çarpıtmak, bozmak",
            examples: [
                "The camera filter distorted the image.",
                "Don't distort the facts.",
                "Anger can distort your judgment.",
                "Heat distorted the metal.",
                "Reporters sometimes distort the truth."
            ],
            level: .c1, topics: [.academic]
        ),
        CommonWord(
            term: "distribute",
            partOfSpeech: "verb",
            ipa: "/dɪˈstrɪbjuːt/",
            countability: "N/A",
            definition: "To give portions or share out.",
            turkishMeaning: "dağıtmak, paylaştırmak",
            examples: [
                "Distribute the materials evenly among the class.",
                "Volunteers distributed food to families in need.",
                "Profits are distributed yearly.",
                "Please distribute these flyers.",
                "The wealth was distributed unfairly."
            ],
            level: .b2, topics: [.business]
        ),
        CommonWord(
            term: "diverse",
            partOfSpeech: "adjective",
            ipa: "/daɪˈvɜːs/",
            countability: "N/A",
            definition: "Showing a lot of variety; different.",
            turkishMeaning: "çeşitli, farklı",
            examples: [
                "This city has a very diverse population.",
                "The menu offers diverse options.",
                "She has diverse interests.",
                "Diverse teams are more creative.",
                "The country has a diverse landscape."
            ],
            level: .b2, topics: [.academic, .general]
        ),
        CommonWord(
            term: "divert",
            partOfSpeech: "verb",
            ipa: "/daɪˈvɜːt/",
            countability: "N/A",
            definition: "To cause a change of course or direction.",
            turkishMeaning: "yönünü değiştirmek, saptırmak",
            examples: [
                "Because of the accident, the police had to divert traffic down a side street.",
                "He tried to divert attention from the issue.",
                "Funds were diverted to emergency relief.",
                "Flights were diverted due to the storm.",
                "The river was diverted to prevent flooding."
            ],
            level: .c1, topics: [.general]
        ),
        CommonWord(
            term: "dynamic",
            partOfSpeech: "adjective",
            ipa: "/daɪˈnæmɪk/",
            countability: "N/A",
            definition: "Constantly changing or full of energy.",
            turkishMeaning: "dinamik, hareketli",
            examples: [
                "The theater has dynamic shows, so you never know what you'll see.",
                "She's a dynamic and inspiring leader.",
                "The market is highly dynamic.",
                "Their relationship is dynamic and evolving.",
                "He brings a dynamic energy to the team."
            ],
            level: .b2, topics: [.business]
        ),
        CommonWord(
            term: "ease",
            partOfSpeech: "verb",
            ipa: "/iːz/",
            countability: "N/A",
            definition: "To reduce unpleasantness or difficulty.",
            turkishMeaning: "rahatlatmak, hafifletmek",
            examples: [
                "This prescription will ease your allergies.",
                "Her smile eased the tension in the room.",
                "Stretching can ease back pain.",
                "Music helped ease his stress.",
                "Negotiations eased the conflict."
            ],
            level: .b2, topics: [.health]
        ),
        CommonWord(
            term: "efficient",
            partOfSpeech: "adjective",
            ipa: "/ɪˈfɪʃnt/",
            countability: "N/A",
            definition: "Maximizing productivity; working well.",
            turkishMeaning: "verimli, etkili",
            examples: [
                "Now that I'm following a schedule at work, I'm much more efficient.",
                "Modern engines are far more efficient.",
                "She runs an efficient team.",
                "We need an efficient way to sort the data.",
                "Solar panels are increasingly efficient."
            ],
            level: .b2, topics: [.work, .business]
        ),
        CommonWord(
            term: "eliminate",
            partOfSpeech: "verb",
            ipa: "/ɪˈlɪmɪneɪt/",
            countability: "N/A",
            definition: "To remove or get rid of completely.",
            turkishMeaning: "elemek, ortadan kaldırmak",
            examples: [
                "Our team lost the match and was eliminated from the competition.",
                "Try to eliminate sugar from your diet.",
                "Police hope to eliminate crime in the area.",
                "We eliminated the bug in the code.",
                "She was eliminated in the first round."
            ],
            level: .b2, topics: [.academic]
        ),
        CommonWord(
            term: "elite",
            partOfSpeech: "noun",
            ipa: "/ɪˈliːt/",
            countability: "countable",
            definition: "A select, above-average group of people.",
            turkishMeaning: "seçkin grup, elit",
            examples: [
                "The elite detective team were sent for when there were big crimes.",
                "She trained with the elite athletes.",
                "The country's elite live in this neighborhood.",
                "Only an elite few qualify for the program.",
                "He belongs to the academic elite."
            ],
            level: .c1, topics: [.business]
        ),
        CommonWord(
            term: "eloquent",
            partOfSpeech: "adjective",
            ipa: "/ˈɛləkwənt/",
            countability: "N/A",
            definition: "Fluent and persuasive in speech or writing.",
            turkishMeaning: "etkili konuşan, belagatli",
            examples: [
                "Her eloquent writing has gained her many fans.",
                "He gave an eloquent speech at the wedding.",
                "She is an eloquent defender of human rights.",
                "His silence was more eloquent than words.",
                "The book is an eloquent tribute to her mother."
            ],
            level: .c2, topics: [.academic]
        ),
        CommonWord(
            term: "emphasize",
            partOfSpeech: "verb",
            ipa: "/ˈɛmfəsaɪz/",
            countability: "N/A",
            definition: "To give special importance to when speaking or writing.",
            turkishMeaning: "vurgulamak, önemini belirtmek",
            examples: [
                "The teacher emphasized the due date of the project.",
                "I'd like to emphasize how important this is.",
                "She emphasizes the word 'always'.",
                "The report emphasizes safety measures.",
                "He emphasized his commitment to the team."
            ],
            level: .b2, topics: [.academic]
        ),
        CommonWord(
            term: "endure",
            partOfSpeech: "verb",
            ipa: "/ɪnˈdjʊə/",
            countability: "N/A",
            definition: "To suffer through something difficult with patience.",
            turkishMeaning: "katlanmak, dayanmak",
            examples: [
                "He has endured four knee operations so far.",
                "Soldiers must endure tough conditions.",
                "Their friendship has endured for decades.",
                "She endured the long flight without complaint.",
                "Few buildings endure for centuries."
            ],
            level: .c1, topics: [.emotions]
        ),
        CommonWord(
            term: "enhance",
            partOfSpeech: "verb",
            ipa: "/ɪnˈhɑːns/",
            countability: "N/A",
            definition: "To intensify, magnify, or improve.",
            turkishMeaning: "geliştirmek, artırmak",
            examples: [
                "The falling snow enhanced the beauty of the small village.",
                "The new lighting enhances the room.",
                "Good design enhances usability.",
                "She enhanced her resume with extra courses.",
                "Cinnamon enhances the flavor of the cake."
            ],
            level: .c1, topics: [.business]
        ),
        CommonWord(
            term: "epitome",
            partOfSpeech: "noun",
            ipa: "/ɪˈpɪtəmi/",
            countability: "countable",
            definition: "A perfect example of something.",
            turkishMeaning: "mükemmel örnek, simge",
            examples: [
                "The duchess is the epitome of class.",
                "He's the epitome of professionalism.",
                "She's the epitome of kindness.",
                "This building is the epitome of modern design.",
                "His behavior was the epitome of rudeness."
            ],
            level: .c2, topics: [.general]
        ),
        CommonWord(
            term: "equivalent",
            partOfSpeech: "adjective",
            ipa: "/ɪˈkwɪvələnt/",
            countability: "N/A",
            definition: "Equal in value, amount, or meaning.",
            turkishMeaning: "eşdeğer, denk",
            examples: [
                "Twenty-four is equivalent to two dozen.",
                "One mile is roughly equivalent to 1.6 kilometers.",
                "Her degree is equivalent to a master's.",
                "The two products are equivalent in quality.",
                "There's no equivalent word in English."
            ],
            level: .b2, topics: [.academic]
        ),
        CommonWord(
            term: "erroneous",
            partOfSpeech: "adjective",
            ipa: "/ɪˈrəʊniəs/",
            countability: "N/A",
            definition: "Incorrect; based on a false belief.",
            turkishMeaning: "hatalı, yanlış",
            examples: [
                "He apologized for his erroneous statement.",
                "The article contained erroneous information.",
                "Their assumptions proved erroneous.",
                "She corrected the erroneous data.",
                "An erroneous report was published."
            ],
            level: .c2, topics: [.academic]
        ),
        CommonWord(
            term: "estimate",
            partOfSpeech: "noun",
            ipa: "/ˈɛstɪmət/",
            countability: "countable",
            definition: "An approximate value or judgment.",
            turkishMeaning: "tahmin, kestirim",
            examples: [
                "Try to get an estimate of the number of people attending the concert.",
                "The contractor gave us an estimate.",
                "By my estimate, we'll arrive at noon.",
                "Official estimates suggest 10,000 attendees.",
                "Her estimate was surprisingly accurate."
            ],
            level: .b2, topics: [.business, .academic]
        ),
        CommonWord(
            term: "evade",
            partOfSpeech: "verb",
            ipa: "/ɪˈveɪd/",
            countability: "N/A",
            definition: "To avoid or escape from someone or something.",
            turkishMeaning: "kaçmak, sıyrılmak",
            examples: [
                "By hiding in the bathroom, we were able to evade the intruder.",
                "He tried to evade the question.",
                "The thief evaded the police.",
                "She evaded responsibility for the mistake.",
                "It's illegal to evade taxes."
            ],
            level: .c1, topics: [.general]
        ),
        CommonWord(
            term: "evaluate",
            partOfSpeech: "verb",
            ipa: "/ɪˈvæljueɪt/",
            countability: "N/A",
            definition: "To assess or judge the value of something.",
            turkishMeaning: "değerlendirmek",
            examples: [
                "At the end of the class, every student will evaluate the professor.",
                "We need to evaluate the situation carefully.",
                "She evaluates job applicants.",
                "Doctors evaluate patients regularly.",
                "Please evaluate the risks before deciding."
            ],
            level: .b2, topics: [.academic]
        ),
        CommonWord(
            term: "evolve",
            partOfSpeech: "verb",
            ipa: "/ɪˈvɒlv/",
            countability: "N/A",
            definition: "To gradually change or develop.",
            turkishMeaning: "evrim geçirmek, gelişmek",
            examples: [
                "The small school evolved into a world-class institution.",
                "Species evolve over millions of years.",
                "Technology evolves rapidly.",
                "His style has evolved a lot.",
                "Our plans evolved as we discussed them."
            ],
            level: .b2, topics: [.academic, .nature]
        ),
        CommonWord(
            term: "exemplary",
            partOfSpeech: "adjective",
            ipa: "/ɪɡˈzɛmpləri/",
            countability: "N/A",
            definition: "Worthy of imitation; serving as a model.",
            turkishMeaning: "örnek teşkil eden",
            examples: [
                "She is an exemplary student, and you should copy her study habits.",
                "His service to the community is exemplary.",
                "The chef's work is exemplary.",
                "She received an exemplary review.",
                "He showed exemplary courage."
            ],
            level: .c2, topics: [.academic]
        ),
        CommonWord(
            term: "exclude",
            partOfSpeech: "verb",
            ipa: "/ɪkˈskluːd/",
            countability: "N/A",
            definition: "To leave out; to keep from being part of.",
            turkishMeaning: "dışlamak, hariç tutmak",
            examples: [
                "The young boy was excluded from his friends' soccer game.",
                "Tax is excluded from the price.",
                "We can't exclude that possibility.",
                "Don't exclude anyone from the meeting.",
                "Smoking is excluded from public spaces."
            ],
            level: .b2, topics: [.general]
        ),
        CommonWord(
            term: "exclusive",
            partOfSpeech: "adjective",
            ipa: "/ɪkˈskluːsɪv/",
            countability: "N/A",
            definition: "Not admitting the majority; restricted.",
            turkishMeaning: "özel, sınırlı",
            examples: [
                "We may not get in since that club is very exclusive.",
                "She gave us an exclusive interview.",
                "It's an exclusive neighborhood.",
                "The offer is exclusive to members.",
                "He has exclusive rights to the song."
            ],
            level: .b2, topics: [.business]
        ),
        CommonWord(
            term: "expand",
            partOfSpeech: "verb",
            ipa: "/ɪkˈspænd/",
            countability: "N/A",
            definition: "To increase in size, amount, or scope.",
            turkishMeaning: "genişlemek, büyümek",
            examples: [
                "Adding air to bike tires will cause them to expand.",
                "The company plans to expand into new markets.",
                "Could you expand on that point?",
                "Her business expanded rapidly.",
                "Metal expands when heated."
            ],
            level: .b2, topics: [.business]
        ),
        CommonWord(
            term: "expertise",
            partOfSpeech: "noun",
            ipa: "/ˌɛkspɜːˈtiːz/",
            countability: "uncountable",
            definition: "Expert knowledge or skill in a particular field.",
            turkishMeaning: "uzmanlık",
            examples: [
                "The surgeon's expertise is knee surgeries.",
                "She has expertise in finance.",
                "Their expertise is unmatched.",
                "We rely on his expertise.",
                "Expertise comes with years of practice."
            ],
            level: .b2, topics: [.work, .business]
        ),
        CommonWord(
            term: "exploit",
            partOfSpeech: "verb",
            ipa: "/ɪkˈsplɔɪt/",
            countability: "N/A",
            definition: "To use selfishly or to take full advantage of.",
            turkishMeaning: "sömürmek, istismar etmek",
            examples: [
                "The company exploited its workers by making them work long hours.",
                "She exploited every opportunity that came her way.",
                "They exploit natural resources.",
                "Don't exploit your friends' kindness.",
                "He exploited a weakness in the system."
            ],
            level: .c1, topics: [.business]
        ),
        CommonWord(
            term: "expose",
            partOfSpeech: "verb",
            ipa: "/ɪkˈspəʊz/",
            countability: "N/A",
            definition: "To reveal or unmask.",
            turkishMeaning: "açığa çıkarmak, ifşa etmek",
            examples: [
                "The emails presented exposed the company's corruption.",
                "Children should be exposed to different cultures.",
                "She exposed the truth about the scandal.",
                "Don't expose your skin to direct sunlight.",
                "The film exposes injustice."
            ],
            level: .b2, topics: [.general]
        ),
        CommonWord(
            term: "extension",
            partOfSpeech: "noun",
            ipa: "/ɪkˈstɛnʃn/",
            countability: "countable",
            definition: "An act of making something longer or larger.",
            turkishMeaning: "uzatma, ek",
            examples: [
                "If you're sick on the day the paper is due, the teacher may give you an extension.",
                "We built an extension on our house.",
                "She got an extension on her visa.",
                "The deadline extension was helpful.",
                "Hair extensions are popular these days."
            ],
            level: .b2, topics: [.academic]
        ),
        CommonWord(
            term: "extract",
            partOfSpeech: "verb",
            ipa: "/ɪkˈstrækt/",
            countability: "N/A",
            definition: "To get or remove something with effort.",
            turkishMeaning: "çıkarmak, almak",
            examples: [
                "The dentist extracted one of my teeth.",
                "We extract oil from the ground.",
                "She extracted a confession from him.",
                "Extract the key points from the article.",
                "Olive oil is extracted from olives."
            ],
            level: .b2, topics: [.academic]
        ),
        CommonWord(
            term: "famine",
            partOfSpeech: "noun",
            ipa: "/ˈfæmɪn/",
            countability: "both",
            definition: "A time when there is an extreme lack of food.",
            turkishMeaning: "kıtlık, açlık",
            examples: [
                "Millions of children in Ethiopia died due to the famine there.",
                "Famine often follows drought.",
                "Aid was sent to areas suffering famine.",
                "The historical famine killed thousands.",
                "Famine and disease often go together."
            ],
            level: .c1, topics: [.nature]
        ),
        CommonWord(
            term: "feasible",
            partOfSpeech: "adjective",
            ipa: "/ˈfiːzəbl/",
            countability: "N/A",
            definition: "Possible to do; capable of being achieved.",
            turkishMeaning: "yapılabilir, uygulanabilir",
            examples: [
                "This study plan sounds feasible even with my work schedule.",
                "Is it feasible to finish by Friday?",
                "The project is technically feasible.",
                "We need to find a feasible solution.",
                "Solar power is now economically feasible."
            ],
            level: .c1, topics: [.business, .academic]
        ),
        CommonWord(
            term: "finite",
            partOfSpeech: "adjective",
            ipa: "/ˈfaɪnaɪt/",
            countability: "N/A",
            definition: "Having an end or limits.",
            turkishMeaning: "sınırlı, sonlu",
            examples: [
                "Remember that life is finite; you're not immortal.",
                "We have finite resources.",
                "Time is a finite resource.",
                "There's a finite number of possibilities.",
                "Our energy supply is finite."
            ],
            level: .c1, topics: [.academic]
        ),
        CommonWord(
            term: "flaw",
            partOfSpeech: "noun",
            ipa: "/flɔː/",
            countability: "countable",
            definition: "A feature that ruins the perfection of something.",
            turkishMeaning: "kusur, hata",
            examples: [
                "I got the diamond for a reduced price since the stone had a flaw.",
                "His plan has one serious flaw.",
                "Everyone has flaws.",
                "There's a flaw in your argument.",
                "The system has design flaws."
            ],
            level: .b2, topics: [.general]
        ),
        CommonWord(
            term: "fluctuate",
            partOfSpeech: "verb",
            ipa: "/ˈflʌktʃueɪt/",
            countability: "N/A",
            definition: "To change continually; to rise and fall.",
            turkishMeaning: "dalgalanmak, değişmek",
            examples: [
                "Temperatures have been fluctuating so much.",
                "Stock prices fluctuate daily.",
                "Her mood fluctuates a lot.",
                "Sales fluctuate with the seasons.",
                "Exchange rates fluctuate constantly."
            ],
            level: .c1, topics: [.business]
        ),
        CommonWord(
            term: "fortify",
            partOfSpeech: "verb",
            ipa: "/ˈfɔːtɪfaɪ/",
            countability: "N/A",
            definition: "To strengthen; to make stronger.",
            turkishMeaning: "güçlendirmek, sağlamlaştırmak",
            examples: [
                "The king decided to fortify the castle walls.",
                "Cereals are often fortified with vitamins.",
                "She fortified herself with coffee.",
                "We need to fortify our defenses.",
                "His words fortified the team."
            ],
            level: .c2, topics: [.general]
        ),
        CommonWord(
            term: "framework",
            partOfSpeech: "noun",
            ipa: "/ˈfreɪmwɜːk/",
            countability: "countable",
            definition: "A basic structure designed to support something.",
            turkishMeaning: "yapı, çerçeve",
            examples: [
                "Skyscrapers must have a strong framework to support all the floors.",
                "We follow an ethical framework.",
                "The legal framework needs updating.",
                "She built a framework for the analysis.",
                "Use a logical framework for the essay."
            ],
            level: .c1, topics: [.academic, .business]
        ),
        CommonWord(
            term: "frivolous",
            partOfSpeech: "adjective",
            ipa: "/ˈfrɪvələs/",
            countability: "N/A",
            definition: "Unnecessary; of little importance.",
            turkishMeaning: "önemsiz, hafifmeşrep",
            examples: [
                "You must stop spending your money on frivolous purchases.",
                "He dismissed it as a frivolous concern.",
                "Don't make frivolous lawsuits.",
                "Her frivolous remarks annoyed everyone.",
                "Avoid frivolous spending."
            ],
            level: .c2, topics: [.general]
        ),
        CommonWord(
            term: "function",
            partOfSpeech: "noun",
            ipa: "/ˈfʌŋkʃn/",
            countability: "countable",
            definition: "A purpose natural to a person or thing.",
            turkishMeaning: "işlev, görev",
            examples: [
                "The function of petals is to attract insects to the plant.",
                "What's the function of this button?",
                "She serves an important function on the team.",
                "The heart's function is to pump blood.",
                "This tool has many useful functions."
            ],
            level: .b2, topics: [.academic]
        ),
        CommonWord(
            term: "fundamental",
            partOfSpeech: "adjective",
            ipa: "/ˌfʌndəˈmɛntl/",
            countability: "N/A",
            definition: "Of primary importance; basic.",
            turkishMeaning: "temel, esas",
            examples: [
                "Learning scales is fundamental to being a good piano player.",
                "Trust is fundamental in any relationship.",
                "These are fundamental human rights.",
                "There's a fundamental flaw in the plan.",
                "Reading is a fundamental skill."
            ],
            level: .b2, topics: [.academic]
        ),
        CommonWord(
            term: "gap",
            partOfSpeech: "noun",
            ipa: "/ɡæp/",
            countability: "countable",
            definition: "A space between two objects or points.",
            turkishMeaning: "boşluk, açık",
            examples: [
                "Be careful to avoid the gap between the two steps.",
                "There's a gap in my knowledge here.",
                "She took a gap year before college.",
                "The income gap continues to grow.",
                "Fill in the gaps in this sentence."
            ],
            level: .b2, topics: [.general]
        ),
        CommonWord(
            term: "garbled",
            partOfSpeech: "adjective",
            ipa: "/ˈɡɑːbld/",
            countability: "N/A",
            definition: "Communication that is distorted and unclear.",
            turkishMeaning: "bozuk, anlaşılmaz",
            examples: [
                "Our answering machine is so bad that people's voices are always garbled.",
                "The message came through garbled.",
                "His explanation was garbled and confusing.",
                "The radio signal was garbled.",
                "She left a garbled voicemail."
            ],
            level: .c2, topics: [.general]
        ),
        CommonWord(
            term: "generate",
            partOfSpeech: "verb",
            ipa: "/ˈdʒɛnəreɪt/",
            countability: "N/A",
            definition: "To produce or create something.",
            turkishMeaning: "üretmek, oluşturmak",
            examples: [
                "The fire generates heat, which keeps the room warm.",
                "The factory generates electricity.",
                "Her idea generated a lot of interest.",
                "We need to generate more revenue.",
                "Wind turbines generate power."
            ],
            level: .b2, topics: [.academic]
        ),
        CommonWord(
            term: "grandiose",
            partOfSpeech: "adjective",
            ipa: "/ˈɡrændiəʊs/",
            countability: "N/A",
            definition: "Pompous; overly grand or important.",
            turkishMeaning: "abartılı, gösterişli",
            examples: [
                "The actress had grandiose ideas of her fame.",
                "His grandiose plans never worked out.",
                "The mansion has grandiose architecture.",
                "She made a grandiose entrance.",
                "Their grandiose promises were broken."
            ],
            level: .c2, topics: [.general]
        ),
        CommonWord(
            term: "hackneyed",
            partOfSpeech: "adjective",
            ipa: "/ˈhæknid/",
            countability: "N/A",
            definition: "Overused and unoriginal.",
            turkishMeaning: "basmakalıp, klişe",
            examples: [
                "His poems contain many hackneyed phrases.",
                "Avoid hackneyed expressions in your writing.",
                "The film's plot is hackneyed.",
                "She rejected the hackneyed advice.",
                "Politicians often use hackneyed slogans."
            ],
            level: .c2, topics: [.academic]
        ),
        CommonWord(
            term: "haphazard",
            partOfSpeech: "adjective",
            ipa: "/hæpˈhæzəd/",
            countability: "N/A",
            definition: "Lacking planning or organization.",
            turkishMeaning: "rastgele, plansız",
            examples: [
                "There was no schedule, so the event was very haphazard.",
                "Her notes were haphazard.",
                "The town developed in a haphazard way.",
                "His approach to studying is haphazard.",
                "The files were stored in a haphazard manner."
            ],
            level: .c2, topics: [.general]
        ),
        CommonWord(
            term: "harsh",
            partOfSpeech: "adjective",
            ipa: "/hɑːʃ/",
            countability: "N/A",
            definition: "Not gentle; unpleasant or cruel.",
            turkishMeaning: "sert, acımasız",
            examples: [
                "Her comments on my performance were very harsh.",
                "The desert has a harsh climate.",
                "His harsh words hurt her feelings.",
                "We faced harsh criticism from the public.",
                "It was a harsh winter."
            ],
            level: .b2, topics: [.emotions, .nature]
        ),
        CommonWord(
            term: "hasty",
            partOfSpeech: "adjective",
            ipa: "/ˈheɪsti/",
            countability: "N/A",
            definition: "In a hurry; done too quickly.",
            turkishMeaning: "aceleci, telaşlı",
            examples: [
                "In order to avoid the police, the robbers made a hasty retreat.",
                "Don't make hasty decisions.",
                "She gave a hasty reply.",
                "It was a hasty marriage.",
                "His hasty conclusion was wrong."
            ],
            level: .c1, topics: [.general]
        ),
        CommonWord(
            term: "hazardous",
            partOfSpeech: "adjective",
            ipa: "/ˈhæzədəs/",
            countability: "N/A",
            definition: "Full of risk; dangerous.",
            turkishMeaning: "tehlikeli, riskli",
            examples: [
                "The nuclear reactor has a lot of hazardous waste.",
                "Driving in fog is hazardous.",
                "The job involves hazardous materials.",
                "Smoking is hazardous to your health.",
                "Hazardous conditions delayed the flight."
            ],
            level: .c1, topics: [.health, .nature]
        ),
        CommonWord(
            term: "hesitate",
            partOfSpeech: "verb",
            ipa: "/ˈhɛzɪteɪt/",
            countability: "N/A",
            definition: "To pause, often due to uncertainty or reluctance.",
            turkishMeaning: "tereddüt etmek, duraksamak",
            examples: [
                "She hesitated before entering the abandoned building.",
                "Don't hesitate to call if you need help.",
                "He hesitated before answering.",
                "I hesitated to disturb her.",
                "She hesitated at the doorway."
            ],
            level: .b2, topics: [.daily]
        ),
        CommonWord(
            term: "hierarchy",
            partOfSpeech: "noun",
            ipa: "/ˈhaɪərɑːki/",
            countability: "countable",
            definition: "A ranking system of people or things.",
            turkishMeaning: "hiyerarşi, sıralama",
            examples: [
                "In the office hierarchy, the manager is higher than the associate.",
                "There's a strict hierarchy in the army.",
                "Many organizations have rigid hierarchies.",
                "She doesn't believe in strict hierarchies.",
                "The hierarchy of needs is a famous theory."
            ],
            level: .c1, topics: [.business, .academic]
        ),
        CommonWord(
            term: "hindrance",
            partOfSpeech: "noun",
            ipa: "/ˈhɪndrəns/",
            countability: "countable",
            definition: "Something that causes delay or resistance.",
            turkishMeaning: "engel, mâni",
            examples: [
                "Her hatred of public transportation is a hindrance in New York City.",
                "His leg injury is a serious hindrance.",
                "Bad weather was a hindrance to our progress.",
                "He moved without any hindrance.",
                "Lack of funds is the main hindrance."
            ],
            level: .c2, topics: [.general]
        ),
        CommonWord(
            term: "hollow",
            partOfSpeech: "adjective",
            ipa: "/ˈhɒləʊ/",
            countability: "N/A",
            definition: "Empty inside.",
            turkishMeaning: "içi boş, oyuk",
            examples: [
                "The dead tree is hollow.",
                "His promises sounded hollow.",
                "She heard a hollow sound.",
                "A hollow chocolate egg is easy to break.",
                "I felt hollow after the news."
            ],
            level: .b2, topics: [.general]
        ),
        CommonWord(
            term: "horror",
            partOfSpeech: "noun",
            ipa: "/ˈhɒrə/",
            countability: "uncountable",
            definition: "An intense feeling of fear or shock.",
            turkishMeaning: "dehşet, korku",
            examples: [
                "The haunted house filled me with horror.",
                "She watched in horror as the accident happened.",
                "Horror movies aren't for me.",
                "He recoiled in horror.",
                "The horror of war affected him deeply."
            ],
            level: .b2, topics: [.emotions]
        ),
        CommonWord(
            term: "hostile",
            partOfSpeech: "adjective",
            ipa: "/ˈhɒstaɪl/",
            countability: "N/A",
            definition: "Extremely unfriendly or aggressive.",
            turkishMeaning: "düşmanca, hasım",
            examples: [
                "My ex-boyfriend's new girlfriend was very hostile towards me.",
                "He gave me a hostile glare.",
                "The audience was hostile to the speaker.",
                "They live in a hostile environment.",
                "She felt hostile after the argument."
            ],
            level: .c1, topics: [.emotions]
        ),
        CommonWord(
            term: "hypothesis",
            partOfSpeech: "noun",
            ipa: "/haɪˈpɒθəsɪs/",
            countability: "countable",
            definition: "An unproven idea that attempts to explain something.",
            turkishMeaning: "hipotez, varsayım",
            examples: [
                "You'll need to conduct an experiment to test your hypothesis.",
                "Her hypothesis was confirmed by the data.",
                "Scientists proposed a new hypothesis.",
                "The hypothesis was eventually disproved.",
                "Let's start with a working hypothesis."
            ],
            level: .c1, topics: [.academic]
        ),
        CommonWord(
            term: "identical",
            partOfSpeech: "adjective",
            ipa: "/aɪˈdɛntɪkl/",
            countability: "N/A",
            definition: "Exactly the same.",
            turkishMeaning: "aynı, özdeş",
            examples: [
                "The twins were completely identical.",
                "Their answers were identical.",
                "These two products are identical.",
                "He has an identical twin brother.",
                "The copies are identical to the original."
            ],
            level: .b2, topics: [.general]
        ),
        CommonWord(
            term: "illiterate",
            partOfSpeech: "adjective",
            ipa: "/ɪˈlɪtərət/",
            countability: "N/A",
            definition: "Unable to read or write.",
            turkishMeaning: "okuma yazma bilmeyen",
            examples: [
                "Because he'd never been able to attend school, the man was illiterate.",
                "Millions of adults are functionally illiterate.",
                "She helps illiterate adults learn to read.",
                "The illiterate population needs support.",
                "He felt computer illiterate at his new job."
            ],
            level: .c1, topics: [.academic]
        ),
        CommonWord(
            term: "illustrate",
            partOfSpeech: "verb",
            ipa: "/ˈɪləstreɪt/",
            countability: "N/A",
            definition: "To explain by using an example or image.",
            turkishMeaning: "örneklendirmek, açıklamak",
            examples: [
                "The professor illustrated the lesson with a personal story.",
                "Let me illustrate my point.",
                "She illustrated children's books.",
                "The chart illustrates the trend clearly.",
                "He illustrated the concept with a diagram."
            ],
            level: .b2, topics: [.academic]
        ),
        CommonWord(
            term: "impact",
            partOfSpeech: "noun",
            ipa: "/ˈɪmpækt/",
            countability: "countable",
            definition: "Effect or influence on something.",
            turkishMeaning: "etki, tesir",
            examples: [
                "His moving words had a large impact on me.",
                "Climate change has a global impact.",
                "The new policy will have a major impact.",
                "Her work has had a lasting impact.",
                "We measure the impact of our programs."
            ],
            level: .b2, topics: [.business, .academic]
        ),
        CommonWord(
            term: "impair",
            partOfSpeech: "verb",
            ipa: "/ɪmˈpɛə/",
            countability: "N/A",
            definition: "To worsen or weaken something.",
            turkishMeaning: "bozmak, zayıflatmak",
            examples: [
                "Drinking alcohol will impair your driving abilities.",
                "Fatigue can impair judgment.",
                "Loud noise can impair hearing.",
                "The injury impaired his performance.",
                "Smoking impairs lung function."
            ],
            level: .c1, topics: [.health]
        ),
        CommonWord(
            term: "implement",
            partOfSpeech: "verb",
            ipa: "/ˈɪmplɪmɛnt/",
            countability: "N/A",
            definition: "To carry out a plan or decision.",
            turkishMeaning: "uygulamak, hayata geçirmek",
            examples: [
                "We will implement the new schedule starting next semester.",
                "The government implemented strict rules.",
                "Let's implement the changes immediately.",
                "She helped implement the new system.",
                "The policy was implemented last year."
            ],
            level: .b2, topics: [.business, .work]
        ),
        CommonWord(
            term: "imply",
            partOfSpeech: "verb",
            ipa: "/ɪmˈplaɪ/",
            countability: "N/A",
            definition: "To strongly suggest without saying directly.",
            turkishMeaning: "ima etmek, sezdirmek",
            examples: [
                "My mother implied that I was the one who forgot to take out the trash.",
                "Are you implying I'm wrong?",
                "Her smile implied agreement.",
                "His silence implied consent.",
                "The data implies a strong correlation."
            ],
            level: .c1, topics: [.academic]
        ),
        CommonWord(
            term: "impose",
            partOfSpeech: "verb",
            ipa: "/ɪmˈpəʊz/",
            countability: "N/A",
            definition: "To force something on someone.",
            turkishMeaning: "dayatmak, zorla kabul ettirmek",
            examples: [
                "After the riots, the mayor imposed a curfew.",
                "Don't impose your views on others.",
                "The court imposed a heavy fine.",
                "Sanctions were imposed on the country.",
                "I hope I'm not imposing on your time."
            ],
            level: .c1, topics: [.business]
        ),
        CommonWord(
            term: "impoverish",
            partOfSpeech: "verb",
            ipa: "/ɪmˈpɒvərɪʃ/",
            countability: "N/A",
            definition: "To reduce to poverty.",
            turkishMeaning: "fakirleştirmek, yoksullaştırmak",
            examples: [
                "These medical bills are going to impoverish me.",
                "War can impoverish entire nations.",
                "He was impoverished by gambling.",
                "Bad decisions impoverished the company.",
                "Pollution can impoverish soil quality."
            ],
            level: .c2, topics: [.business]
        ),
        CommonWord(
            term: "incentive",
            partOfSpeech: "noun",
            ipa: "/ɪnˈsɛntɪv/",
            countability: "countable",
            definition: "A reason or motivation to do something.",
            turkishMeaning: "teşvik, motivasyon",
            examples: [
                "I hate my job, but the big paychecks are a good incentive.",
                "Bonuses are a strong incentive.",
                "There's no incentive to change.",
                "Tax breaks provide incentives for investment.",
                "She offered her kids an incentive to study."
            ],
            level: .c1, topics: [.business]
        ),
        CommonWord(
            term: "incessant",
            partOfSpeech: "adjective",
            ipa: "/ɪnˈsɛsənt/",
            countability: "N/A",
            definition: "Continuing without pause.",
            turkishMeaning: "aralıksız, durmaksızın",
            examples: [
                "I can't sleep because of the dog's incessant barking.",
                "Her incessant complaints annoy me.",
                "The incessant rain ruined our holiday.",
                "He talked with incessant energy.",
                "Incessant noise filled the street."
            ],
            level: .c2, topics: [.general]
        ),
        CommonWord(
            term: "incidental",
            partOfSpeech: "adjective",
            ipa: "/ˌɪnsɪˈdɛntl/",
            countability: "N/A",
            definition: "A minor or secondary part.",
            turkishMeaning: "tesadüfi, ikinci derecede",
            examples: [
                "Don't worry about this quiz; it's only an incidental part of your grade.",
                "Travel was an incidental expense.",
                "These details are incidental to the story.",
                "Music plays an incidental role in the film.",
                "Her injury was incidental and not serious."
            ],
            level: .c2, topics: [.academic]
        ),
        CommonWord(
            term: "incite",
            partOfSpeech: "verb",
            ipa: "/ɪnˈsaɪt/",
            countability: "N/A",
            definition: "To urge or stir up.",
            turkishMeaning: "kışkırtmak, tahrik etmek",
            examples: [
                "The ringleader incited the soldiers to rebellion.",
                "His speech incited the crowd to riot.",
                "Don't incite violence.",
                "The article incited public outrage.",
                "She was charged with inciting a riot."
            ],
            level: .c2, topics: [.general]
        ),
        CommonWord(
            term: "inclination",
            partOfSpeech: "noun",
            ipa: "/ˌɪnklɪˈneɪʃn/",
            countability: "countable",
            definition: "A preference or tendency.",
            turkishMeaning: "eğilim, meyil",
            examples: [
                "My inclination is to go to bed early.",
                "She has a natural inclination for music.",
                "My first inclination was to refuse.",
                "He shows an inclination to argue.",
                "I have no inclination to travel."
            ],
            level: .c1, topics: [.emotions]
        ),
        CommonWord(
            term: "incompetent",
            partOfSpeech: "adjective",
            ipa: "/ɪnˈkɒmpɪtənt/",
            countability: "N/A",
            definition: "Incapable; lacking ability.",
            turkishMeaning: "yetersiz, beceriksiz",
            examples: [
                "The incompetent worker was fired from his job.",
                "He's totally incompetent at his job.",
                "The government was accused of being incompetent.",
                "An incompetent doctor can be dangerous.",
                "Don't act incompetent in front of clients."
            ],
            level: .c1, topics: [.work]
        ),
        CommonWord(
            term: "inconsistent",
            partOfSpeech: "adjective",
            ipa: "/ˌɪnkənˈsɪstənt/",
            countability: "N/A",
            definition: "Changing randomly; not steady.",
            turkishMeaning: "tutarsız, kararsız",
            examples: [
                "His pitching has been very inconsistent all season.",
                "Her grades are inconsistent.",
                "The data is inconsistent with our theory.",
                "His behavior is inconsistent.",
                "The service was inconsistent."
            ],
            level: .b2, topics: [.academic]
        ),
        CommonWord(
            term: "indefatigable",
            partOfSpeech: "adjective",
            ipa: "/ˌɪndɪˈfætɪɡəbl/",
            countability: "N/A",
            definition: "Untiring; persisting despite fatigue.",
            turkishMeaning: "yorulmaz, bitmez tükenmez",
            examples: [
                "She is an indefatigable hiker and can walk all day.",
                "His indefatigable spirit inspires us.",
                "She's an indefatigable advocate for children.",
                "He showed indefatigable energy.",
                "Their indefatigable efforts paid off."
            ],
            level: .c2, topics: [.emotions]
        ),
        CommonWord(
            term: "indisputable",
            partOfSpeech: "adjective",
            ipa: "/ˌɪndɪˈspjuːtəbl/",
            countability: "N/A",
            definition: "Not able to be challenged or denied.",
            turkishMeaning: "tartışılmaz, su götürmez",
            examples: [
                "She's the indisputable star of the basketball team.",
                "The evidence is indisputable.",
                "His talent is indisputable.",
                "It's an indisputable fact.",
                "Her contributions to science are indisputable."
            ],
            level: .c2, topics: [.academic]
        ),
        CommonWord(
            term: "ineffective",
            partOfSpeech: "adjective",
            ipa: "/ˌɪnɪˈfɛktɪv/",
            countability: "N/A",
            definition: "Not producing any major impact.",
            turkishMeaning: "etkisiz, sonuçsuz",
            examples: [
                "The drug was shown to be ineffective at curing cancer.",
                "Their strategy proved ineffective.",
                "These rules are ineffective.",
                "His efforts were ineffective.",
                "Ineffective leadership hurts morale."
            ],
            level: .b2, topics: [.academic]
        ),
        CommonWord(
            term: "inevitable",
            partOfSpeech: "adjective",
            ipa: "/ɪnˈɛvɪtəbl/",
            countability: "N/A",
            definition: "Unable to be avoided.",
            turkishMeaning: "kaçınılmaz",
            examples: [
                "Even if you're healthy, death is inevitable in the end.",
                "Change is inevitable in life.",
                "Their breakup was inevitable.",
                "Some delays are inevitable.",
                "It was inevitable that we would meet again."
            ],
            level: .c1, topics: [.general]
        ),
        CommonWord(
            term: "infer",
            partOfSpeech: "verb",
            ipa: "/ɪnˈfɜː/",
            countability: "N/A",
            definition: "To guess based on evidence.",
            turkishMeaning: "çıkarsamak, anlamak",
            examples: [
                "I inferred that she was annoyed based on her body language.",
                "What can we infer from these results?",
                "He inferred a deeper meaning.",
                "Readers can infer the character's emotions.",
                "Detectives infer motive from evidence."
            ],
            level: .c1, topics: [.academic]
        ),
        CommonWord(
            term: "inflate",
            partOfSpeech: "verb",
            ipa: "/ɪnˈfleɪt/",
            countability: "N/A",
            definition: "To increase in size or amount.",
            turkishMeaning: "şişirmek, abartmak",
            examples: [
                "Getting a promotion has really inflated his ego.",
                "Please inflate the balloons before the party.",
                "Prices have been inflated recently.",
                "Don't inflate your accomplishments.",
                "Inflate the tires before driving."
            ],
            level: .b2, topics: [.business]
        ),
        CommonWord(
            term: "influence",
            partOfSpeech: "noun",
            ipa: "/ˈɪnflʊəns/",
            countability: "both",
            definition: "The ability to have an effect on something.",
            turkishMeaning: "etki, nüfuz",
            examples: [
                "The older sister has been a positive influence on her younger siblings.",
                "He used his influence to help her.",
                "Music has a strong influence on me.",
                "She has a lot of influence in politics.",
                "Be careful of negative influences."
            ],
            level: .b2, topics: [.business, .general]
        ),
        CommonWord(
            term: "inhibit",
            partOfSpeech: "verb",
            ipa: "/ɪnˈhɪbɪt/",
            countability: "N/A",
            definition: "To hinder or restrain.",
            turkishMeaning: "engellemek, kısıtlamak",
            examples: [
                "This cleaning spray inhibits the growth of bacteria.",
                "Shyness can inhibit social interaction.",
                "Cold weather inhibits plant growth.",
                "Don't let fear inhibit you.",
                "The drug inhibits enzyme activity."
            ],
            level: .c1, topics: [.academic, .health]
        ),
        CommonWord(
            term: "initial",
            partOfSpeech: "adjective",
            ipa: "/ɪˈnɪʃl/",
            countability: "N/A",
            definition: "The first; earliest in time.",
            turkishMeaning: "ilk, başlangıç",
            examples: [
                "She was the initial president of the company.",
                "My initial reaction was to laugh.",
                "The initial cost is high but worth it.",
                "We need to address the initial problem.",
                "The initial results are promising."
            ],
            level: .b2, topics: [.general]
        ),
        CommonWord(
            term: "inquiry",
            partOfSpeech: "noun",
            ipa: "/ɪnˈkwaɪəri/",
            countability: "countable",
            definition: "An investigation to determine the truth.",
            turkishMeaning: "soruşturma, araştırma",
            examples: [
                "Congress launched an inquiry after the senator was accused of bribery.",
                "We received many inquiries about the job.",
                "The inquiry took six months.",
                "An official inquiry is underway.",
                "Please direct your inquiries to HR."
            ],
            level: .c1, topics: [.academic, .business]
        ),
        CommonWord(
            term: "integral",
            partOfSpeech: "adjective",
            ipa: "/ˈɪntɪɡrəl/",
            countability: "N/A",
            definition: "Necessary to complete the whole.",
            turkishMeaning: "ayrılmaz, tamamlayıcı",
            examples: [
                "You can't quit. You're an integral part of this team.",
                "Music is integral to the film's success.",
                "Trust is integral to any relationship.",
                "She plays an integral role.",
                "These features are integral to the design."
            ],
            level: .c1, topics: [.academic]
        ),
        CommonWord(
            term: "integrate",
            partOfSpeech: "verb",
            ipa: "/ˈɪntɪɡreɪt/",
            countability: "N/A",
            definition: "To combine into a whole.",
            turkishMeaning: "birleştirmek, kaynaştırmak",
            examples: [
                "When making a cake, you need to fully integrate the wet and dry ingredients.",
                "The schools integrated in the 1960s.",
                "She integrated quickly into her new team.",
                "We need to integrate these systems.",
                "Try to integrate exercise into your daily life."
            ],
            level: .b2, topics: [.academic]
        ),
        CommonWord(
            term: "interpret",
            partOfSpeech: "verb",
            ipa: "/ɪnˈtɜːprɪt/",
            countability: "N/A",
            definition: "To explain the meaning of something.",
            turkishMeaning: "yorumlamak, çevirmek",
            examples: [
                "I need you to interpret this German speech for me.",
                "How do you interpret his behavior?",
                "Critics interpret the poem differently.",
                "She interprets dreams as a hobby.",
                "The judge interpreted the law."
            ],
            level: .b2, topics: [.academic]
        ),
        CommonWord(
            term: "intervene",
            partOfSpeech: "verb",
            ipa: "/ˌɪntəˈviːn/",
            countability: "N/A",
            definition: "To come between to change what is happening.",
            turkishMeaning: "araya girmek, müdahale etmek",
            examples: [
                "When the toddlers couldn't share, their mothers had to intervene.",
                "The police intervened in the fight.",
                "She refused to intervene in their argument.",
                "Foreign governments intervened in the conflict.",
                "Don't intervene unless necessary."
            ],
            level: .c1, topics: [.general]
        ),
        CommonWord(
            term: "intrepid",
            partOfSpeech: "adjective",
            ipa: "/ɪnˈtrɛpɪd/",
            countability: "N/A",
            definition: "Fearless and adventurous.",
            turkishMeaning: "korkusuz, cesur",
            examples: [
                "The intrepid mountain climber reached the top of Mt. Everest.",
                "She's an intrepid traveler.",
                "Intrepid explorers discovered new lands.",
                "The intrepid reporter went into the war zone.",
                "His intrepid spirit was admirable."
            ],
            level: .c2, topics: [.general]
        ),
        CommonWord(
            term: "intricate",
            partOfSpeech: "adjective",
            ipa: "/ˈɪntrɪkət/",
            countability: "N/A",
            definition: "Highly detailed; complex.",
            turkishMeaning: "karmaşık, ince",
            examples: [
                "The pattern on this blanket is so intricate.",
                "Her work involves intricate calculations.",
                "It's an intricate problem.",
                "The watch has an intricate mechanism.",
                "He carved intricate designs in wood."
            ],
            level: .c1, topics: [.general]
        ),
        CommonWord(
            term: "invasive",
            partOfSpeech: "adjective",
            ipa: "/ɪnˈveɪsɪv/",
            countability: "N/A",
            definition: "Intrusive; tending to spread harmfully.",
            turkishMeaning: "istilacı, müdahaleci",
            examples: [
                "We found the stranger's questions too personal and very invasive.",
                "Invasive species threaten local wildlife.",
                "The surgery was minimally invasive.",
                "Avoid invasive plants in your garden.",
                "He gave an invasive interview."
            ],
            level: .c1, topics: [.health, .nature]
        ),
        CommonWord(
            term: "investigate",
            partOfSpeech: "verb",
            ipa: "/ɪnˈvɛstɪɡeɪt/",
            countability: "N/A",
            definition: "To examine or study carefully.",
            turkishMeaning: "araştırmak, soruşturmak",
            examples: [
                "The police are going to investigate the crime scene.",
                "Scientists investigate the cause of the disease.",
                "I'll investigate the matter and report back.",
                "They are investigating new technologies.",
                "She investigated the strange noise."
            ],
            level: .b2, topics: [.academic]
        ),
        CommonWord(
            term: "irascible",
            partOfSpeech: "adjective",
            ipa: "/ɪˈræsɪbl/",
            countability: "N/A",
            definition: "Easy to anger; quick-tempered.",
            turkishMeaning: "çabuk öfkelenen, sinirli",
            examples: [
                "Even though my grandfather seems irascible, he's actually very loving.",
                "Her irascible boss intimidated everyone.",
                "He has an irascible temper.",
                "The irascible old man yelled at the kids.",
                "Don't be so irascible."
            ],
            level: .c2, topics: [.emotions]
        ),
        CommonWord(
            term: "irony",
            partOfSpeech: "noun",
            ipa: "/ˈaɪrəni/",
            countability: "uncountable",
            definition: "Use of words to give a meaning opposite to their literal meaning.",
            turkishMeaning: "ironi, alaycılık",
            examples: [
                "\"I love spending my Friday nights doing homework,\" she said with irony.",
                "There's a certain irony in the situation.",
                "He has a sharp sense of irony.",
                "The irony of his statement was lost on us.",
                "Literature often uses irony for effect."
            ],
            level: .c1, topics: [.academic]
        ),
        CommonWord(
            term: "irresolute",
            partOfSpeech: "adjective",
            ipa: "/ɪˈrɛzəluːt/",
            countability: "N/A",
            definition: "Uncertain; lacking decisiveness.",
            turkishMeaning: "kararsız",
            examples: [
                "Not sure which direction to go in, he stood irresolute.",
                "She remained irresolute about the offer.",
                "His irresolute manner annoyed everyone.",
                "He looked irresolute and confused.",
                "Don't be irresolute — make a decision."
            ],
            level: .c2, topics: [.emotions]
        ),
        CommonWord(
            term: "jargon",
            partOfSpeech: "noun",
            ipa: "/ˈdʒɑːɡən/",
            countability: "uncountable",
            definition: "Words specific to a certain job or group.",
            turkishMeaning: "meslek dili, jargon",
            examples: [
                "To be a successful doctor, you'll need to learn a lot of medical jargon.",
                "The report is full of legal jargon.",
                "Avoid jargon when writing for general readers.",
                "I don't understand the technical jargon.",
                "Each profession has its own jargon."
            ],
            level: .c1, topics: [.academic, .work]
        ),
        CommonWord(
            term: "jointly",
            partOfSpeech: "adverb",
            ipa: "/ˈdʒɔɪntli/",
            countability: "N/A",
            definition: "Together; in cooperation.",
            turkishMeaning: "ortaklaşa, birlikte",
            examples: [
                "The newlyweds jointly opened up a bank account.",
                "The award was given jointly to both researchers.",
                "They own the company jointly.",
                "The two governments acted jointly.",
                "The decision was made jointly."
            ],
            level: .b2, topics: [.business]
        ),
        CommonWord(
            term: "knack",
            partOfSpeech: "noun",
            ipa: "/næk/",
            countability: "countable",
            definition: "A special talent or skill.",
            turkishMeaning: "yetenek, beceri",
            examples: [
                "My brother has a real knack for solving tricky math problems.",
                "She has a knack for making friends.",
                "He has a knack for fixing things.",
                "It takes some knack to use these chopsticks.",
                "She has a knack for storytelling."
            ],
            level: .c1, topics: [.general]
        ),
        CommonWord(
            term: "labor",
            partOfSpeech: "noun",
            ipa: "/ˈleɪbə/",
            countability: "uncountable",
            definition: "Work or effort.",
            turkishMeaning: "emek, iş gücü",
            examples: [
                "Building a house requires a lot of labor.",
                "Manual labor can be exhausting.",
                "The cost of labor has risen sharply.",
                "Their labor was finally rewarded.",
                "Skilled labor is in high demand."
            ],
            level: .b2, topics: [.work]
        ),
        CommonWord(
            term: "lag",
            partOfSpeech: "verb",
            ipa: "/læɡ/",
            countability: "N/A",
            definition: "To fall behind or move slowly.",
            turkishMeaning: "geri kalmak, gecikmek",
            examples: [
                "I stayed with the front runners for the first few miles, then I began to lag.",
                "Sales are lagging this quarter.",
                "His grades have been lagging.",
                "The video is lagging behind the audio.",
                "Don't lag behind the group."
            ],
            level: .b2, topics: [.business]
        ),
        CommonWord(
            term: "lampoon",
            partOfSpeech: "verb",
            ipa: "/læmˈpuːn/",
            countability: "N/A",
            definition: "To mock or ridicule, often publicly.",
            turkishMeaning: "alay etmek, hicvetmek",
            examples: [
                "The cartoonist lampooned the president's speech.",
                "The show lampoons politicians weekly.",
                "She lampooned his pretentious style.",
                "Critics lampooned the new movie.",
                "Newspapers often lampoon public figures."
            ],
            level: .c2, topics: [.academic]
        ),
        CommonWord(
            term: "languish",
            partOfSpeech: "verb",
            ipa: "/ˈlæŋɡwɪʃ/",
            countability: "N/A",
            definition: "To become weak or be neglected.",
            turkishMeaning: "zayıflamak, ihmal edilmek",
            examples: [
                "During winter break, my plants languished without water.",
                "The project languished for years.",
                "He languished in prison.",
                "Her career languished after the scandal.",
                "The book languished on the shelf."
            ],
            level: .c2, topics: [.nature]
        ),
        CommonWord(
            term: "lecture",
            partOfSpeech: "noun",
            ipa: "/ˈlɛktʃə/",
            countability: "countable",
            definition: "A talk given to an audience.",
            turkishMeaning: "ders, konferans",
            examples: [
                "The professor will give a 30 minute lecture before the quiz.",
                "I missed yesterday's lecture.",
                "She gave a lecture on climate change.",
                "His lectures are always interesting.",
                "Don't give me a lecture about saving money."
            ],
            level: .b2, topics: [.academic]
        ),
        CommonWord(
            term: "leery",
            partOfSpeech: "adjective",
            ipa: "/ˈlɪəri/",
            countability: "N/A",
            definition: "Wary; cautious of someone or something.",
            turkishMeaning: "şüpheli, ihtiyatlı",
            examples: [
                "I'm leery of taking the dark-looking shortcut.",
                "She's leery of strangers.",
                "I'm leery about investing right now.",
                "Be leery of deals that sound too good.",
                "He became leery of online shopping."
            ],
            level: .c2, topics: [.emotions]
        ),
        CommonWord(
            term: "legitimate",
            partOfSpeech: "adjective",
            ipa: "/lɪˈdʒɪtɪmət/",
            countability: "N/A",
            definition: "Lawful; conforming to accepted rules.",
            turkishMeaning: "meşru, yasal",
            examples: [
                "The way he became mayor is completely legitimate.",
                "She has a legitimate complaint.",
                "Is this a legitimate business?",
                "His concerns are legitimate.",
                "There's no legitimate reason to refuse."
            ],
            level: .c1, topics: [.business]
        ),
        CommonWord(
            term: "lenient",
            partOfSpeech: "adjective",
            ipa: "/ˈliːniənt/",
            countability: "N/A",
            definition: "Merciful; less harsh than expected.",
            turkishMeaning: "hoşgörülü, yumuşak",
            examples: [
                "The judge gave the criminal a lenient sentence.",
                "Her parents are very lenient.",
                "The school has lenient dress codes.",
                "Don't be too lenient with the children.",
                "His teacher was lenient about late work."
            ],
            level: .c1, topics: [.general]
        ),
        CommonWord(
            term: "likely",
            partOfSpeech: "adjective",
            ipa: "/ˈlaɪkli/",
            countability: "N/A",
            definition: "Probable; expected to happen.",
            turkishMeaning: "muhtemel, olası",
            examples: [
                "I don't have much homework, so it's likely I'll be able to go out tonight.",
                "Rain is likely tomorrow.",
                "She is the most likely candidate.",
                "He's likely to win the election.",
                "It's likely that he forgot."
            ],
            level: .b2, topics: [.general]
        ),
        CommonWord(
            term: "ludicrous",
            partOfSpeech: "adjective",
            ipa: "/ˈluːdɪkrəs/",
            countability: "N/A",
            definition: "Ridiculous; absurd.",
            turkishMeaning: "gülünç, saçma",
            examples: [
                "His claims about me are absolutely ludicrous.",
                "The idea is ludicrous.",
                "The price is ludicrous.",
                "What a ludicrous suggestion!",
                "Her outfit looked ludicrous."
            ],
            level: .c2, topics: [.general]
        ),
        CommonWord(
            term: "maintain",
            partOfSpeech: "verb",
            ipa: "/meɪnˈteɪn/",
            countability: "N/A",
            definition: "To continue at the same level or to keep in good condition.",
            turkishMeaning: "sürdürmek, korumak",
            examples: [
                "She has maintained the same weight since high school.",
                "The garden is well maintained.",
                "He maintained his innocence.",
                "We need to maintain good relations.",
                "Regular service maintains your car's value."
            ],
            level: .b2, topics: [.general]
        ),
        CommonWord(
            term: "major",
            partOfSpeech: "adjective",
            ipa: "/ˈmeɪdʒə/",
            countability: "N/A",
            definition: "Very important or significant.",
            turkishMeaning: "büyük, önemli",
            examples: [
                "This test is a major part of your final grade.",
                "There has been a major change in policy.",
                "Health is a major concern.",
                "The major cities are connected by train.",
                "She played a major role in the project."
            ],
            level: .b2, topics: [.general]
        ),
        CommonWord(
            term: "manipulate",
            partOfSpeech: "verb",
            ipa: "/məˈnɪpjəleɪt/",
            countability: "N/A",
            definition: "To influence, especially in an unfair way.",
            turkishMeaning: "manipüle etmek, yönlendirmek",
            examples: [
                "He tried to manipulate the results of the election.",
                "She knows how to manipulate her parents.",
                "The data was manipulated to look better.",
                "Don't let him manipulate you.",
                "He manipulated the controls expertly."
            ],
            level: .c1, topics: [.general]
        ),
        CommonWord(
            term: "maximize",
            partOfSpeech: "verb",
            ipa: "/ˈmæksɪmaɪz/",
            countability: "N/A",
            definition: "To increase to the greatest possible size.",
            turkishMeaning: "en yüksek seviyeye çıkarmak",
            examples: [
                "The store's goal this year is to maximize its profit.",
                "We want to maximize our impact.",
                "Maximize the window on your screen.",
                "She tries to maximize her time.",
                "Companies always seek to maximize gains."
            ],
            level: .b2, topics: [.business]
        ),
        CommonWord(
            term: "measure",
            partOfSpeech: "verb",
            ipa: "/ˈmɛʒə/",
            countability: "N/A",
            definition: "To find the size and dimensions of something.",
            turkishMeaning: "ölçmek",
            examples: [
                "By measuring the tree, I found it was seven feet tall.",
                "How do you measure success?",
                "The tailor measured my waist.",
                "We measure progress weekly.",
                "It's hard to measure happiness."
            ],
            level: .b2, topics: [.academic]
        ),
        CommonWord(
            term: "mediocre",
            partOfSpeech: "adjective",
            ipa: "/ˌmiːdiˈəʊkə/",
            countability: "N/A",
            definition: "Ordinary; of average quality.",
            turkishMeaning: "vasat, ortalama",
            examples: [
                "The meal the chef made was only mediocre.",
                "His performance was mediocre.",
                "Don't settle for mediocre results.",
                "The film received mediocre reviews.",
                "Their service was mediocre at best."
            ],
            level: .c1, topics: [.general]
        ),
        CommonWord(
            term: "mend",
            partOfSpeech: "verb",
            ipa: "/mɛnd/",
            countability: "N/A",
            definition: "To fix something that is broken.",
            turkishMeaning: "tamir etmek, onarmak",
            examples: [
                "My mother will mend the hole in my shirt.",
                "It will take time to mend their relationship.",
                "He mended the broken chair.",
                "Time mends all wounds.",
                "She mended the fence yesterday."
            ],
            level: .b2, topics: [.daily]
        ),
        CommonWord(
            term: "method",
            partOfSpeech: "noun",
            ipa: "/ˈmɛθəd/",
            countability: "countable",
            definition: "A way of doing something.",
            turkishMeaning: "yöntem, metot",
            examples: [
                "Her method for making bread takes three days.",
                "This method works best for me.",
                "What teaching method do you use?",
                "Try a different method.",
                "Modern methods are more efficient."
            ],
            level: .b2, topics: [.academic]
        ),
        CommonWord(
            term: "migrate",
            partOfSpeech: "verb",
            ipa: "/maɪˈɡreɪt/",
            countability: "N/A",
            definition: "To move from one place to another.",
            turkishMeaning: "göç etmek",
            examples: [
                "Every fall, the geese migrate to Florida.",
                "Many families migrated for better jobs.",
                "We migrated our data to a new server.",
                "Birds migrate thousands of miles.",
                "Workers often migrate for opportunities."
            ],
            level: .c1, topics: [.nature, .travel]
        ),
        CommonWord(
            term: "minimum",
            partOfSpeech: "noun",
            ipa: "/ˈmɪnɪməm/",
            countability: "countable",
            definition: "The smallest or lowest amount possible.",
            turkishMeaning: "asgari, minimum",
            examples: [
                "You need to get a minimum of 70% on the test to pass.",
                "Keep noise to a minimum.",
                "The minimum wage was raised.",
                "What's the minimum order?",
                "He sleeps a minimum of six hours."
            ],
            level: .b2, topics: [.general]
        ),
        CommonWord(
            term: "misleading",
            partOfSpeech: "adjective",
            ipa: "/mɪsˈliːdɪŋ/",
            countability: "N/A",
            definition: "Giving the wrong idea or impression.",
            turkishMeaning: "yanıltıcı",
            examples: [
                "The advertisement for the weight loss pills is very misleading.",
                "His statement was misleading.",
                "Don't use misleading headlines.",
                "The map was misleading.",
                "Their claims turned out to be misleading."
            ],
            level: .c1, topics: [.academic]
        ),
        CommonWord(
            term: "modify",
            partOfSpeech: "verb",
            ipa: "/ˈmɒdɪfaɪ/",
            countability: "N/A",
            definition: "To change something slightly.",
            turkishMeaning: "değiştirmek, uyarlamak",
            examples: [
                "I need to modify my style so it looks more professional.",
                "We modified the recipe to use less sugar.",
                "Please modify the document.",
                "The car has been modified.",
                "Modify your behavior accordingly."
            ],
            level: .b2, topics: [.academic]
        ),
        CommonWord(
            term: "morose",
            partOfSpeech: "adjective",
            ipa: "/məˈrəʊs/",
            countability: "N/A",
            definition: "Gloomy and depressed.",
            turkishMeaning: "asık suratlı, kasvetli",
            examples: [
                "The boy was morose after hearing he didn't make the football team.",
                "She fell into a morose silence.",
                "He's been morose all week.",
                "The morose man rarely spoke.",
                "Rainy days make him morose."
            ],
            level: .c2, topics: [.emotions]
        ),
        CommonWord(
            term: "negligent",
            partOfSpeech: "adjective",
            ipa: "/ˈnɛɡlɪdʒənt/",
            countability: "N/A",
            definition: "Failing to take proper care; neglectful.",
            turkishMeaning: "ihmalkâr, dikkatsiz",
            examples: [
                "The negligent babysitter invited her friends over while the children were upstairs.",
                "The driver was negligent and caused the accident.",
                "He was found negligent in his duties.",
                "Negligent behavior can have legal consequences.",
                "Don't be negligent about safety."
            ],
            level: .c1, topics: [.general]
        ),
        CommonWord(
            term: "nonchalant",
            partOfSpeech: "adjective",
            ipa: "/ˈnɒnʃələnt/",
            countability: "N/A",
            definition: "Indifferent; appearing unconcerned.",
            turkishMeaning: "kayıtsız, umursamaz",
            examples: [
                "I was hurt when my friend greeted me so nonchalantly.",
                "He was nonchalant about the news.",
                "She gave a nonchalant shrug.",
                "His nonchalant attitude annoyed me.",
                "She tried to appear nonchalant."
            ],
            level: .c2, topics: [.emotions]
        ),
        CommonWord(
            term: "obey",
            partOfSpeech: "verb",
            ipa: "/əˈbeɪ/",
            countability: "N/A",
            definition: "To follow orders or instructions.",
            turkishMeaning: "itaat etmek, uymak",
            examples: [
                "My dog always obeys me when I ask her to sit.",
                "Children should obey their parents.",
                "We must obey the law.",
                "Soldiers are trained to obey orders.",
                "He refused to obey the rules."
            ],
            level: .b2, topics: [.general]
        ),
        CommonWord(
            term: "obtain",
            partOfSpeech: "verb",
            ipa: "/əbˈteɪn/",
            countability: "N/A",
            definition: "To get or acquire something.",
            turkishMeaning: "elde etmek, edinmek",
            examples: [
                "The spy obtained the secret codes we need.",
                "You can obtain a copy from the office.",
                "She obtained her degree last year.",
                "How did you obtain this information?",
                "He obtained permission to leave."
            ],
            level: .b2, topics: [.academic]
        ),
        CommonWord(
            term: "obvious",
            partOfSpeech: "adjective",
            ipa: "/ˈɒbviəs/",
            countability: "N/A",
            definition: "Easily understood or seen.",
            turkishMeaning: "açık, belli",
            examples: [
                "The large poster of Michael Jackson made it obvious who her favorite singer was.",
                "It's obvious that he's lying.",
                "The answer is obvious.",
                "For obvious reasons, she didn't say anything.",
                "His talent is obvious."
            ],
            level: .b2, topics: [.general]
        ),
        CommonWord(
            term: "opponent",
            partOfSpeech: "noun",
            ipa: "/əˈpəʊnənt/",
            countability: "countable",
            definition: "Someone on the opposite side of a game or contest.",
            turkishMeaning: "rakip, karşı taraf",
            examples: [
                "The soccer player blocked her opponent's shot at the goal.",
                "He defeated his opponent in the final.",
                "She's a worthy opponent.",
                "Her opponent was unprepared.",
                "Listen to your opponent's arguments."
            ],
            level: .b2, topics: [.general]
        ),
        CommonWord(
            term: "oppress",
            partOfSpeech: "verb",
            ipa: "/əˈprɛs/",
            countability: "N/A",
            definition: "To unfairly burden or treat cruelly.",
            turkishMeaning: "ezmek, baskı altında tutmak",
            examples: [
                "The royal family has oppressed the peasants for ten generations.",
                "The regime oppressed its citizens.",
                "She felt oppressed by her workload.",
                "Many groups were oppressed historically.",
                "Heat oppressed the entire city."
            ],
            level: .c1, topics: [.general]
        ),
        CommonWord(
            term: "origin",
            partOfSpeech: "noun",
            ipa: "/ˈɒrɪdʒɪn/",
            countability: "countable",
            definition: "The source; where something began.",
            turkishMeaning: "köken, başlangıç",
            examples: [
                "The explorers are trying to find the origin of the Nile.",
                "The word has Latin origins.",
                "Her family is of Italian origin.",
                "We don't know the origin of the virus.",
                "What's the origin of this tradition?"
            ],
            level: .b2, topics: [.academic]
        ),
        CommonWord(
            term: "paradigm",
            partOfSpeech: "noun",
            ipa: "/ˈpærədaɪm/",
            countability: "countable",
            definition: "A typical example or model.",
            turkishMeaning: "paradigma, örnek model",
            examples: [
                "This work of art is a paradigm of the period.",
                "We're seeing a paradigm shift in education.",
                "His career became a paradigm of success.",
                "The textbook is a paradigm of clarity.",
                "It's a new paradigm for thinking."
            ],
            level: .c2, topics: [.academic]
        ),
        CommonWord(
            term: "parsimonious",
            partOfSpeech: "adjective",
            ipa: "/ˌpɑːsɪˈməʊniəs/",
            countability: "N/A",
            definition: "Frugal; stingy with money.",
            turkishMeaning: "cimri, tutumlu",
            examples: [
                "The parsimonious woman only donated a dollar to charity.",
                "His parsimonious habits saved a fortune.",
                "She is parsimonious with praise.",
                "The boss was parsimonious with raises.",
                "Their parsimonious budget left no room for fun."
            ],
            level: .c2, topics: [.business]
        ),
        CommonWord(
            term: "partake",
            partOfSpeech: "verb",
            ipa: "/pɑːˈteɪk/",
            countability: "N/A",
            definition: "To join in or take part in.",
            turkishMeaning: "katılmak, paylaşmak",
            examples: [
                "My leg was feeling much better, so I decided to partake in the soccer match.",
                "Would you like to partake in lunch?",
                "He didn't partake in the discussion.",
                "Children may partake in the activities.",
                "She partook of the feast."
            ],
            level: .c2, topics: [.general]
        ),
        CommonWord(
            term: "partial",
            partOfSpeech: "adjective",
            ipa: "/ˈpɑːʃl/",
            countability: "N/A",
            definition: "Preferring one option, or incomplete.",
            turkishMeaning: "kısmi, yanlı",
            examples: [
                "We can get strawberry, but I'm partial to chocolate.",
                "I have a partial refund.",
                "She gave a partial answer.",
                "He's partial to old movies.",
                "The eclipse was only partial."
            ],
            level: .c1, topics: [.general]
        ),
        CommonWord(
            term: "paucity",
            partOfSpeech: "noun",
            ipa: "/ˈpɔːsəti/",
            countability: "uncountable",
            definition: "Something existing in very small amounts; scarcity.",
            turkishMeaning: "azlık, kıtlık",
            examples: [
                "During the drought, the town had a paucity of fresh water.",
                "There's a paucity of evidence.",
                "The paucity of jobs hurt the economy.",
                "She noted a paucity of detail in the report.",
                "A paucity of options frustrated him."
            ],
            level: .c2, topics: [.academic]
        ),
        CommonWord(
            term: "peak",
            partOfSpeech: "noun",
            ipa: "/piːk/",
            countability: "countable",
            definition: "The highest or most important point.",
            turkishMeaning: "zirve, doruk",
            examples: [
                "Winning the championship was the peak of his career.",
                "She climbed to the mountain's peak.",
                "Traffic reaches its peak at 6pm.",
                "He's at the peak of his game.",
                "The peak of summer is very hot."
            ],
            level: .b2, topics: [.business, .nature]
        ),
        CommonWord(
            term: "peripheral",
            partOfSpeech: "adjective",
            ipa: "/pəˈrɪfərəl/",
            countability: "N/A",
            definition: "Located on the side or edge; not central.",
            turkishMeaning: "çevresel, ikincil",
            examples: [
                "There are some peripheral fights going on at the outdoor concert.",
                "Peripheral vision is important when driving.",
                "These are peripheral issues.",
                "He works in a peripheral department.",
                "Connect peripheral devices to your computer."
            ],
            level: .c1, topics: [.academic]
        ),
        CommonWord(
            term: "permeate",
            partOfSpeech: "verb",
            ipa: "/ˈpɜːmieɪt/",
            countability: "N/A",
            definition: "To penetrate or pass through.",
            turkishMeaning: "nüfuz etmek, yayılmak",
            examples: [
                "Let the maple syrup permeate your waffles before eating them.",
                "The smell of coffee permeated the house.",
                "Fear permeated the crowd.",
                "Water permeated the soil.",
                "Music permeates every corner of the cafe."
            ],
            level: .c2, topics: [.general]
        ),
        CommonWord(
            term: "persist",
            partOfSpeech: "verb",
            ipa: "/pəˈsɪst/",
            countability: "N/A",
            definition: "To continue, especially when facing opposition.",
            turkishMeaning: "ısrar etmek, devam etmek",
            examples: [
                "I may have lost my last six games, but I will continue to persist trying to win.",
                "If you persist, you'll succeed.",
                "Symptoms may persist for weeks.",
                "Don't persist with that bad idea.",
                "The rumor persisted for years."
            ],
            level: .c1, topics: [.emotions]
        ),
        CommonWord(
            term: "pertain",
            partOfSpeech: "verb",
            ipa: "/pəˈteɪn/",
            countability: "N/A",
            definition: "To relate to or be relevant to.",
            turkishMeaning: "ilgili olmak, ait olmak",
            examples: [
                "How does your question pertain to the lecture?",
                "These rules pertain to all employees.",
                "The documents pertain to the case.",
                "What he said doesn't pertain to me.",
                "Information pertaining to the project is here."
            ],
            level: .c2, topics: [.academic]
        ),
        CommonWord(
            term: "phase",
            partOfSpeech: "noun",
            ipa: "/feɪz/",
            countability: "countable",
            definition: "A stage in a process.",
            turkishMeaning: "evre, aşama",
            examples: [
                "In high school, I went through a phase where I only wore black clothes.",
                "The first phase of the project is done.",
                "It's just a phase she's going through.",
                "We're entering a new phase.",
                "Each phase has its challenges."
            ],
            level: .b2, topics: [.academic]
        ),
        CommonWord(
            term: "poll",
            partOfSpeech: "noun",
            ipa: "/pəʊl/",
            countability: "countable",
            definition: "A record of opinions or votes.",
            turkishMeaning: "anket, oylama",
            examples: [
                "The polls show that my candidate is going to win the election.",
                "A recent poll showed surprising results.",
                "Polls open at 7 AM.",
                "She topped the poll for best teacher.",
                "Online polls are easy to create."
            ],
            level: .c1, topics: [.business]
        ),
        CommonWord(
            term: "potent",
            partOfSpeech: "adjective",
            ipa: "/ˈpəʊtnt/",
            countability: "N/A",
            definition: "Powerful; having strong effect.",
            turkishMeaning: "güçlü, etkili",
            examples: [
                "Only take one sleeping pill since they're very potent.",
                "Coffee is a potent stimulant.",
                "He gave a potent speech.",
                "The drug is potent and effective.",
                "Love is a potent force."
            ],
            level: .c1, topics: [.health]
        ),
        CommonWord(
            term: "pragmatic",
            partOfSpeech: "adjective",
            ipa: "/præɡˈmætɪk/",
            countability: "N/A",
            definition: "Practical and sensible.",
            turkishMeaning: "pragmatik, pratik",
            examples: [
                "Your boyfriend is too dramatic. I think you need a more pragmatic man.",
                "She took a pragmatic approach.",
                "We need pragmatic solutions, not theories.",
                "He's pragmatic about money.",
                "Their pragmatic decisions saved time."
            ],
            level: .c2, topics: [.business]
        ),
        CommonWord(
            term: "praise",
            partOfSpeech: "verb",
            ipa: "/preɪz/",
            countability: "N/A",
            definition: "To give approval or admiration.",
            turkishMeaning: "övmek, takdir etmek",
            examples: [
                "The book is the best I've ever read; I can't praise it enough.",
                "Teachers should praise effort.",
                "She praised her team's hard work.",
                "The critic praised the film.",
                "He was praised for his bravery."
            ],
            level: .b2, topics: [.emotions]
        ),
        CommonWord(
            term: "precede",
            partOfSpeech: "verb",
            ipa: "/prɪˈsiːd/",
            countability: "N/A",
            definition: "To come before in time, order, or rank.",
            turkishMeaning: "önce gelmek, öncülük etmek",
            examples: [
                "The flower girls preceded the bride down the aisle.",
                "A storm preceded the calm.",
                "His speech was preceded by a short film.",
                "Symptoms often precede the illness.",
                "His career preceded mine by ten years."
            ],
            level: .c1, topics: [.academic]
        ),
        CommonWord(
            term: "precise",
            partOfSpeech: "adjective",
            ipa: "/prɪˈsaɪs/",
            countability: "N/A",
            definition: "Exact; accurate in every detail.",
            turkishMeaning: "kesin, tam",
            examples: [
                "When collecting data, your measurements need to be precise.",
                "Be precise with your wording.",
                "I need the precise time of the event.",
                "She gave precise instructions.",
                "Precise calculations are required."
            ],
            level: .b2, topics: [.academic]
        ),
        CommonWord(
            term: "prestigious",
            partOfSpeech: "adjective",
            ipa: "/prɛˈstɪdʒəs/",
            countability: "N/A",
            definition: "Having a high reputation.",
            turkishMeaning: "saygın, itibarlı",
            examples: [
                "Harvard is one of the most prestigious colleges in the United States.",
                "He won a prestigious award.",
                "She works for a prestigious firm.",
                "It's a prestigious neighborhood.",
                "The journal is highly prestigious."
            ],
            level: .c1, topics: [.academic]
        ),
        CommonWord(
            term: "prevalent",
            partOfSpeech: "adjective",
            ipa: "/ˈprɛvələnt/",
            countability: "N/A",
            definition: "Widespread; commonly occurring.",
            turkishMeaning: "yaygın, hâkim",
            examples: [
                "If more people don't wash their hands, disease will become more prevalent.",
                "This view is prevalent among scientists.",
                "Smartphones are prevalent everywhere.",
                "The flu is prevalent in winter.",
                "Bullying is prevalent in schools."
            ],
            level: .c1, topics: [.academic]
        ),
        CommonWord(
            term: "primary",
            partOfSpeech: "adjective",
            ipa: "/ˈpraɪməri/",
            countability: "N/A",
            definition: "First; most important.",
            turkishMeaning: "birincil, asıl",
            examples: [
                "Maeve's primary goal in life is to become a doctor.",
                "Our primary concern is safety.",
                "What's your primary source of income?",
                "Red is a primary color.",
                "Education is of primary importance."
            ],
            level: .b2, topics: [.general]
        ),
        CommonWord(
            term: "prior",
            partOfSpeech: "adjective",
            ipa: "/ˈpraɪə/",
            countability: "N/A",
            definition: "Previous or earlier.",
            turkishMeaning: "önceki, daha önceki",
            examples: [
                "Prior to becoming a teacher, Elena worked as a book editor.",
                "She had no prior experience.",
                "Prior arrangements were made.",
                "He has a prior commitment.",
                "Make a reservation prior to your visit."
            ],
            level: .b2, topics: [.academic]
        ),
        CommonWord(
            term: "proceed",
            partOfSpeech: "verb",
            ipa: "/prəˈsiːd/",
            countability: "N/A",
            definition: "To continue doing something.",
            turkishMeaning: "devam etmek, ilerlemek",
            examples: [
                "I'm sorry for interrupting; please proceed with your speech.",
                "We will proceed with the plan.",
                "Please proceed to gate 22.",
                "The investigation proceeded smoothly.",
                "Let's proceed to the next item."
            ],
            level: .c1, topics: [.general]
        ),
        CommonWord(
            term: "progeny",
            partOfSpeech: "noun",
            ipa: "/ˈprɒdʒəni/",
            countability: "uncountable",
            definition: "Offspring; descendants.",
            turkishMeaning: "soy, döl",
            examples: [
                "The dog's progeny all have yellow fur.",
                "His progeny will inherit the estate.",
                "She has no progeny.",
                "Their progeny went on to do great things.",
                "Scientists studied the progeny of the plant."
            ],
            level: .c2, topics: [.academic]
        ),
        CommonWord(
            term: "promote",
            partOfSpeech: "verb",
            ipa: "/prəˈməʊt/",
            countability: "N/A",
            definition: "To further the progress or sales of something.",
            turkishMeaning: "tanıtmak, terfi ettirmek",
            examples: [
                "I'm promoting this new indie movie so more people will buy tickets.",
                "She was promoted to manager.",
                "Exercise promotes good health.",
                "We promote diversity in our company.",
                "The campaign promotes recycling."
            ],
            level: .b2, topics: [.business]
        ),
        CommonWord(
            term: "prosper",
            partOfSpeech: "verb",
            ipa: "/ˈprɒspə/",
            countability: "N/A",
            definition: "To do well; to be successful financially.",
            turkishMeaning: "başarılı olmak, gelişmek",
            examples: [
                "Dave hopes his new business will prosper and make him a millionaire.",
                "The town prospered during the boom.",
                "May your family prosper.",
                "Plants prosper in this climate.",
                "Their farm prospered for generations."
            ],
            level: .c1, topics: [.business]
        ),
        CommonWord(
            term: "proximity",
            partOfSpeech: "noun",
            ipa: "/prɒkˈsɪməti/",
            countability: "uncountable",
            definition: "Nearness in time or space.",
            turkishMeaning: "yakınlık",
            examples: [
                "The twins bought houses in close proximity to each other.",
                "The hotel's proximity to the beach is great.",
                "Proximity to family is important.",
                "In close proximity to the airport.",
                "Their proximity helped them collaborate."
            ],
            level: .c1, topics: [.academic]
        ),
        CommonWord(
            term: "quarrel",
            partOfSpeech: "noun",
            ipa: "/ˈkwɒrəl/",
            countability: "countable",
            definition: "A disagreement or argument.",
            turkishMeaning: "kavga, anlaşmazlık",
            examples: [
                "Nina and her boyfriend always quarrel over money.",
                "They had a quarrel last night.",
                "I have no quarrel with you.",
                "Don't quarrel over little things.",
                "Their quarrel ended their friendship."
            ],
            level: .c1, topics: [.emotions]
        ),
        CommonWord(
            term: "range",
            partOfSpeech: "noun",
            ipa: "/reɪndʒ/",
            countability: "countable",
            definition: "The distance between two things, often max and min.",
            turkishMeaning: "aralık, menzil",
            examples: [
                "The range of ages at the concert spanned from 12 to 65.",
                "Our store offers a wide range of products.",
                "The price range is wide.",
                "Out of range of the wifi signal.",
                "Her vocal range is impressive."
            ],
            level: .b2, topics: [.general]
        ),
        CommonWord(
            term: "rank",
            partOfSpeech: "noun",
            ipa: "/ræŋk/",
            countability: "countable",
            definition: "An official position or station.",
            turkishMeaning: "rütbe, sıra",
            examples: [
                "Archibald was promoted to the rank of first captain.",
                "She holds a high rank in the military.",
                "The team ranks first in the league.",
                "His rank is above mine.",
                "They rank among the best."
            ],
            level: .b2, topics: [.business]
        ),
        CommonWord(
            term: "rebuke",
            partOfSpeech: "noun",
            ipa: "/rɪˈbjuːk/",
            countability: "countable",
            definition: "A sharp expression of disapproval.",
            turkishMeaning: "azar, sert eleştiri",
            examples: [
                "After staying out too late, Grace received a rebuke from her parents.",
                "He got a stern rebuke from the boss.",
                "The judge issued a rebuke to the lawyer.",
                "Her rebuke was harsh but fair.",
                "Public rebukes can be embarrassing."
            ],
            level: .c2, topics: [.emotions]
        ),
        CommonWord(
            term: "recapitulate",
            partOfSpeech: "verb",
            ipa: "/ˌriːkəˈpɪtʃəleɪt/",
            countability: "N/A",
            definition: "To give a brief summary.",
            turkishMeaning: "özetlemek",
            examples: [
                "The politician recapitulated his main points at the end of his speech.",
                "Let me recapitulate what we've discussed.",
                "She recapitulated the chapter.",
                "He recapitulated the argument briefly.",
                "Please recapitulate the key findings."
            ],
            level: .c2, topics: [.academic]
        ),
        CommonWord(
            term: "recede",
            partOfSpeech: "verb",
            ipa: "/rɪˈsiːd/",
            countability: "N/A",
            definition: "To retreat or move back.",
            turkishMeaning: "çekilmek, gerilemek",
            examples: [
                "Two days after the flood, the seawater finally began to recede.",
                "His hairline is starting to recede.",
                "The memory will recede with time.",
                "Pain receded after the medication.",
                "The shoreline receded over the centuries."
            ],
            level: .c1, topics: [.nature]
        ),
        CommonWord(
            term: "reform",
            partOfSpeech: "verb",
            ipa: "/rɪˈfɔːm/",
            countability: "N/A",
            definition: "To make changes that improve something.",
            turkishMeaning: "reform yapmak, ıslah etmek",
            examples: [
                "Melanie's father is in charge of reforming the school system.",
                "We need to reform the tax code.",
                "He reformed his behavior after prison.",
                "Health care must be reformed.",
                "The party promised to reform the system."
            ],
            level: .c1, topics: [.business, .academic]
        ),
        CommonWord(
            term: "regulate",
            partOfSpeech: "verb",
            ipa: "/ˈrɛɡjəleɪt/",
            countability: "N/A",
            definition: "To control a process so it functions correctly.",
            turkishMeaning: "düzenlemek, ayarlamak",
            examples: [
                "Ben needs to regulate how much he eats to stay healthy.",
                "The government regulates the industry.",
                "Thermostats regulate temperature.",
                "We need to regulate our sleep schedule.",
                "Banks are heavily regulated."
            ],
            level: .c1, topics: [.business]
        ),
        CommonWord(
            term: "reinforce",
            partOfSpeech: "verb",
            ipa: "/ˌriːɪnˈfɔːs/",
            countability: "N/A",
            definition: "To strengthen with added support.",
            turkishMeaning: "güçlendirmek, pekiştirmek",
            examples: [
                "The builders reinforced the house's wooden frame with steel beams.",
                "This study reinforces our hypothesis.",
                "Praise reinforces good behavior.",
                "Reinforce the message with examples.",
                "His words reinforced my decision."
            ],
            level: .c1, topics: [.academic]
        ),
        CommonWord(
            term: "reject",
            partOfSpeech: "verb",
            ipa: "/rɪˈdʒɛkt/",
            countability: "N/A",
            definition: "To refuse to accept something.",
            turkishMeaning: "reddetmek",
            examples: [
                "Lydia rejected my invitation to the homecoming dance.",
                "His application was rejected.",
                "She rejected the offer.",
                "Don't reject change outright.",
                "The committee rejected the proposal."
            ],
            level: .b2, topics: [.general]
        ),
        CommonWord(
            term: "release",
            partOfSpeech: "verb",
            ipa: "/rɪˈliːs/",
            countability: "N/A",
            definition: "To free or to allow to be known.",
            turkishMeaning: "serbest bırakmak, yayınlamak",
            examples: [
                "The CEO decided to release the company's profits from last year.",
                "The album will be released next month.",
                "Please release the prisoner.",
                "She released a deep sigh.",
                "He released his grip on the rope."
            ],
            level: .b2, topics: [.general]
        ),
        CommonWord(
            term: "rely",
            partOfSpeech: "verb",
            ipa: "/rɪˈlaɪ/",
            countability: "N/A",
            definition: "To depend on someone or something.",
            turkishMeaning: "güvenmek, bel bağlamak",
            examples: [
                "I rely on coffee to get me through my mornings.",
                "We rely on our friends for support.",
                "Don't rely on luck.",
                "Many people rely on public transport.",
                "She relies on her team."
            ],
            level: .b2, topics: [.general]
        ),
        CommonWord(
            term: "reproach",
            partOfSpeech: "verb",
            ipa: "/rɪˈprəʊtʃ/",
            countability: "N/A",
            definition: "To express disapproval or disappointment.",
            turkishMeaning: "sitem etmek, kınamak",
            examples: [
                "The coach reproached the players for failing to play their best.",
                "She reproached him for being late.",
                "I reproached myself for the mistake.",
                "Don't reproach her too harshly.",
                "He looked at me with reproach."
            ],
            level: .c2, topics: [.emotions]
        ),
        CommonWord(
            term: "require",
            partOfSpeech: "verb",
            ipa: "/rɪˈkwaɪə/",
            countability: "N/A",
            definition: "To need for a specific purpose.",
            turkishMeaning: "gerektirmek",
            examples: [
                "The camping trip requires that every participant bring food.",
                "This job requires special skills.",
                "The law requires you to pay taxes.",
                "Plants require water and sunlight.",
                "Success requires hard work."
            ],
            level: .b2, topics: [.general]
        ),
        CommonWord(
            term: "resent",
            partOfSpeech: "verb",
            ipa: "/rɪˈzɛnt/",
            countability: "N/A",
            definition: "To feel bitterness or anger towards someone.",
            turkishMeaning: "içerlemek, kin tutmak",
            examples: [
                "I've always resented my sister because she is my mother's favorite.",
                "He resents being told what to do.",
                "She resented his criticism.",
                "Don't resent others' success.",
                "I resent your tone."
            ],
            level: .c1, topics: [.emotions]
        ),
        CommonWord(
            term: "resign",
            partOfSpeech: "verb",
            ipa: "/rɪˈzaɪn/",
            countability: "N/A",
            definition: "To give up an office or position.",
            turkishMeaning: "istifa etmek",
            examples: [
                "Due to his declining health, the mayor decided to resign from office.",
                "She resigned from her job.",
                "He resigned in protest.",
                "I'm resigned to my fate.",
                "The board accepted his resignation."
            ],
            level: .c1, topics: [.work, .business]
        ),
        CommonWord(
            term: "resist",
            partOfSpeech: "verb",
            ipa: "/rɪˈzɪst/",
            countability: "N/A",
            definition: "To withstand the effect of something.",
            turkishMeaning: "direnmek, karşı koymak",
            examples: [
                "Resist the impulse to have ice cream for breakfast.",
                "She couldn't resist a slice of cake.",
                "The army resisted the attack.",
                "He resisted change for years.",
                "I can't resist that smile."
            ],
            level: .b2, topics: [.general]
        ),
        CommonWord(
            term: "resolve",
            partOfSpeech: "verb",
            ipa: "/rɪˈzɒlv/",
            countability: "N/A",
            definition: "To come to a firm decision.",
            turkishMeaning: "kararlı olmak, çözmek",
            examples: [
                "Matt resolved to get better grades next semester.",
                "We need to resolve this issue quickly.",
                "She resolved to quit smoking.",
                "The conflict was resolved peacefully.",
                "Let's resolve the matter today."
            ],
            level: .c1, topics: [.general]
        ),
        CommonWord(
            term: "restrict",
            partOfSpeech: "verb",
            ipa: "/rɪˈstrɪkt/",
            countability: "N/A",
            definition: "To confine or keep within limits.",
            turkishMeaning: "kısıtlamak, sınırlamak",
            examples: [
                "My doctor told me to restrict myself to one glass of wine a day.",
                "Access is restricted to staff.",
                "Don't restrict your imagination.",
                "Speeds are restricted in school zones.",
                "He restricts his diet for health reasons."
            ],
            level: .b2, topics: [.business]
        ),
        CommonWord(
            term: "retain",
            partOfSpeech: "verb",
            ipa: "/rɪˈteɪn/",
            countability: "N/A",
            definition: "To continue to keep something.",
            turkishMeaning: "saklamak, korumak",
            examples: [
                "I've decided to retain my normal hairstyle.",
                "The team retained the championship.",
                "Please retain a copy for your records.",
                "She retains a strong accent.",
                "The company retains top talent."
            ],
            level: .c1, topics: [.business]
        ),
        CommonWord(
            term: "retract",
            partOfSpeech: "verb",
            ipa: "/rɪˈtrækt/",
            countability: "N/A",
            definition: "To withdraw a statement, or to draw back.",
            turkishMeaning: "geri almak, çekmek",
            examples: [
                "After numerous errors were found, the newspaper retracted the story.",
                "He had to retract his accusation.",
                "The cat retracted its claws.",
                "She retracted her offer.",
                "The landing gear retracted smoothly."
            ],
            level: .c2, topics: [.academic]
        ),
        CommonWord(
            term: "retrieve",
            partOfSpeech: "verb",
            ipa: "/rɪˈtriːv/",
            countability: "N/A",
            definition: "To bring back; to get something back.",
            turkishMeaning: "geri almak, kurtarmak",
            examples: [
                "Alexis got out of the car to retrieve the ball.",
                "I retrieved my files from the cloud.",
                "The dog retrieved the stick.",
                "She retrieved her bag from the lost-and-found.",
                "Try to retrieve the deleted email."
            ],
            level: .b2, topics: [.technology]
        ),
        CommonWord(
            term: "rhetorical",
            partOfSpeech: "adjective",
            ipa: "/rɪˈtɒrɪkl/",
            countability: "N/A",
            definition: "Used just for style or impact rather than for an answer.",
            turkishMeaning: "retorik, hitap sanatına ait",
            examples: [
                "You aren't expected to actually answer rhetorical questions.",
                "His speech was full of rhetorical flourishes.",
                "Was that a rhetorical question?",
                "Rhetorical devices add power to writing.",
                "It's just rhetorical, not literal."
            ],
            level: .c2, topics: [.academic]
        ),
        CommonWord(
            term: "rigid",
            partOfSpeech: "adjective",
            ipa: "/ˈrɪdʒɪd/",
            countability: "N/A",
            definition: "Stiff; unyielding; inflexible.",
            turkishMeaning: "katı, sert",
            examples: [
                "The base of the treehouse was rigid and sturdy.",
                "He has very rigid views on this.",
                "Their rules are too rigid.",
                "Her body went rigid with fear.",
                "Don't be so rigid in your thinking."
            ],
            level: .c1, topics: [.general]
        ),
        CommonWord(
            term: "rotate",
            partOfSpeech: "verb",
            ipa: "/rəʊˈteɪt/",
            countability: "N/A",
            definition: "To turn around a central point.",
            turkishMeaning: "döndürmek, dönmek",
            examples: [
                "Rotate the sculpture so I can see the other side.",
                "Earth rotates on its axis.",
                "We rotate the staff every six months.",
                "Please rotate your tires.",
                "Crops should be rotated to maintain soil quality."
            ],
            level: .b2, topics: [.general]
        ),
        CommonWord(
            term: "safeguard",
            partOfSpeech: "verb",
            ipa: "/ˈseɪfɡɑːd/",
            countability: "N/A",
            definition: "To protect or ensure safety.",
            turkishMeaning: "korumak, güvence altına almak",
            examples: [
                "A retirement fund is one way to safeguard your finances.",
                "We must safeguard children's privacy.",
                "Use strong passwords to safeguard your data.",
                "Laws safeguard consumer rights.",
                "She safeguarded the documents in a safe."
            ],
            level: .c1, topics: [.business]
        ),
        CommonWord(
            term: "scrutinize",
            partOfSpeech: "verb",
            ipa: "/ˈskruːtɪnaɪz/",
            countability: "N/A",
            definition: "To examine very carefully.",
            turkishMeaning: "incelemek, ayrıntıyla araştırmak",
            examples: [
                "The judges scrutinized every entry.",
                "Critics scrutinize his every move.",
                "She scrutinized the contract.",
                "Auditors scrutinize the books.",
                "Detectives scrutinized the evidence."
            ],
            level: .c2, topics: [.academic]
        ),
        CommonWord(
            term: "section",
            partOfSpeech: "noun",
            ipa: "/ˈsɛkʃn/",
            countability: "countable",
            definition: "A part of the whole.",
            turkishMeaning: "bölüm, kısım",
            examples: [
                "This section of the stadium dressed completely in red.",
                "The book has five sections.",
                "Read the introduction section first.",
                "Find shoes in the men's section.",
                "Cut the cake into eight sections."
            ],
            level: .b2, topics: [.general]
        ),
        CommonWord(
            term: "select",
            partOfSpeech: "verb",
            ipa: "/sɪˈlɛkt/",
            countability: "N/A",
            definition: "To choose carefully.",
            turkishMeaning: "seçmek",
            examples: [
                "Jane selected a blue dress to wear to the wedding.",
                "Please select an option from the menu.",
                "She was selected for the team.",
                "Select your password carefully.",
                "He selects only the best ingredients."
            ],
            level: .b2, topics: [.general]
        ),
        CommonWord(
            term: "sequence",
            partOfSpeech: "noun",
            ipa: "/ˈsiːkwəns/",
            countability: "countable",
            definition: "Things that follow each other in a certain order.",
            turkishMeaning: "sıra, dizi",
            examples: [
                "Librarians need to know how to order books in the correct sequence.",
                "Follow the sequence of steps.",
                "What's the next number in this sequence?",
                "The DNA sequence was analyzed.",
                "The events happened in quick sequence."
            ],
            level: .b2, topics: [.academic]
        ),
        CommonWord(
            term: "severe",
            partOfSpeech: "adjective",
            ipa: "/sɪˈvɪə/",
            countability: "N/A",
            definition: "Harsh or strict; very serious.",
            turkishMeaning: "şiddetli, ağır",
            examples: [
                "The robbers suffered severe consequences for stealing.",
                "She has a severe headache.",
                "There were severe storms last night.",
                "The penalty is severe.",
                "He suffered severe injuries."
            ],
            level: .b2, topics: [.health]
        ),
        CommonWord(
            term: "shallow",
            partOfSpeech: "adjective",
            ipa: "/ˈʃæləʊ/",
            countability: "N/A",
            definition: "Not deep.",
            turkishMeaning: "sığ, yüzeysel",
            examples: [
                "The water is very shallow here.",
                "His knowledge is shallow.",
                "She gave a shallow smile.",
                "Avoid shallow conversations.",
                "Take shallow breaths during meditation."
            ],
            level: .b2, topics: [.nature]
        ),
        CommonWord(
            term: "shelter",
            partOfSpeech: "noun",
            ipa: "/ˈʃɛltə/",
            countability: "both",
            definition: "Something that protects from harm.",
            turkishMeaning: "sığınak, barınak",
            examples: [
                "The empty barn gave the men shelter during the storm.",
                "We sought shelter from the rain.",
                "The animal shelter needs volunteers.",
                "She built a small shelter from leaves.",
                "Everyone deserves food and shelter."
            ],
            level: .b2, topics: [.daily]
        ),
        CommonWord(
            term: "shrink",
            partOfSpeech: "verb",
            ipa: "/ʃrɪŋk/",
            countability: "N/A",
            definition: "To become smaller.",
            turkishMeaning: "küçülmek, çekmek",
            examples: [
                "Hopefully this cream will cause my scar to shrink.",
                "My sweater shrank in the dryer.",
                "Profits have shrunk this year.",
                "Don't shrink from your duties.",
                "The forest is shrinking."
            ],
            level: .b2, topics: [.general]
        ),
        CommonWord(
            term: "significant",
            partOfSpeech: "adjective",
            ipa: "/sɪɡˈnɪfɪkənt/",
            countability: "N/A",
            definition: "Important; noteworthy.",
            turkishMeaning: "önemli, anlamlı",
            examples: [
                "The Gettysburg Address was a significant event during the Civil War.",
                "There was a significant rise in sales.",
                "Her contributions are significant.",
                "It's a significant moment in history.",
                "The differences are not significant."
            ],
            level: .b2, topics: [.academic]
        ),
        CommonWord(
            term: "source",
            partOfSpeech: "noun",
            ipa: "/sɔːs/",
            countability: "countable",
            definition: "A person, place, or thing from which something comes.",
            turkishMeaning: "kaynak, köken",
            examples: [
                "You shouldn't use Wikipedia as a source when writing school papers.",
                "Sunlight is a source of vitamin D.",
                "Cite your sources properly.",
                "What's your source of information?",
                "She's a reliable source."
            ],
            level: .b2, topics: [.academic]
        ),
        CommonWord(
            term: "sparse",
            partOfSpeech: "adjective",
            ipa: "/spɑːs/",
            countability: "N/A",
            definition: "Thinly scattered; not dense.",
            turkishMeaning: "seyrek, dağınık",
            examples: [
                "There were just a few sparse trees here and there.",
                "Attendance was sparse.",
                "He has sparse hair.",
                "The desert has sparse vegetation.",
                "Information is sparse on this topic."
            ],
            level: .c1, topics: [.nature]
        ),
        CommonWord(
            term: "specify",
            partOfSpeech: "verb",
            ipa: "/ˈspɛsɪfaɪ/",
            countability: "N/A",
            definition: "To clearly indicate which one.",
            turkishMeaning: "belirtmek, tanımlamak",
            examples: [
                "You need to specify which size shirt you want.",
                "Please specify the date and time.",
                "The contract specifies the terms.",
                "Specify your requirements clearly.",
                "He didn't specify a deadline."
            ],
            level: .c1, topics: [.academic]
        ),
        CommonWord(
            term: "speculate",
            partOfSpeech: "verb",
            ipa: "/ˈspɛkjəleɪt/",
            countability: "N/A",
            definition: "To form a theory without strong evidence.",
            turkishMeaning: "tahminde bulunmak, spekülasyon yapmak",
            examples: [
                "My sister loves to speculate on the private lives of celebrities.",
                "We can only speculate about the future.",
                "Investors speculate in the stock market.",
                "She speculated that he was lying.",
                "It's pointless to speculate without facts."
            ],
            level: .c1, topics: [.business]
        ),
        CommonWord(
            term: "solitary",
            partOfSpeech: "adjective",
            ipa: "/ˈsɒlɪtəri/",
            countability: "N/A",
            definition: "Alone; without others.",
            turkishMeaning: "yalnız, tek başına",
            examples: [
                "The hermit lives a solitary existence deep in the mountains.",
                "She enjoys solitary walks.",
                "He led a solitary life.",
                "A solitary tree stood in the field.",
                "Writing is a solitary activity."
            ],
            level: .c1, topics: [.emotions]
        ),
        CommonWord(
            term: "somber",
            partOfSpeech: "adjective",
            ipa: "/ˈsɒmbə/",
            countability: "N/A",
            definition: "Gloomy or depressing.",
            turkishMeaning: "kasvetli, hüzünlü",
            examples: [
                "After losing the competition, the chess players were very somber.",
                "The funeral had a somber atmosphere.",
                "He wore somber colors to the meeting.",
                "Her face turned somber.",
                "A somber mood filled the room."
            ],
            level: .c2, topics: [.emotions]
        ),
        CommonWord(
            term: "soothe",
            partOfSpeech: "verb",
            ipa: "/suːð/",
            countability: "N/A",
            definition: "To calm or comfort.",
            turkishMeaning: "yatıştırmak, sakinleştirmek",
            examples: [
                "The mother sang a lullaby to soothe her crying baby.",
                "Music soothes my nerves.",
                "Aloe vera soothes burns.",
                "His words soothed her worries.",
                "Take a warm bath to soothe sore muscles."
            ],
            level: .c1, topics: [.emotions]
        ),
        CommonWord(
            term: "squalid",
            partOfSpeech: "adjective",
            ipa: "/ˈskwɒlɪd/",
            countability: "N/A",
            definition: "Filthy and unpleasant.",
            turkishMeaning: "pis, sefil",
            examples: [
                "The shelter was squalid and overcrowded.",
                "They lived in squalid conditions.",
                "The hotel room was squalid.",
                "He grew up in squalid surroundings.",
                "Reformers fought to improve squalid neighborhoods."
            ],
            level: .c2, topics: [.general]
        ),
        CommonWord(
            term: "stable",
            partOfSpeech: "adjective",
            ipa: "/ˈsteɪbl/",
            countability: "N/A",
            definition: "Unlikely to change or fail.",
            turkishMeaning: "istikrarlı, sağlam",
            examples: [
                "We're lucky to live in a country with such a stable government.",
                "Her condition is stable.",
                "The economy is stable now.",
                "He has a stable job.",
                "The structure is stable and safe."
            ],
            level: .b2, topics: [.business]
        ),
        CommonWord(
            term: "stagnant",
            partOfSpeech: "adjective",
            ipa: "/ˈstæɡnənt/",
            countability: "N/A",
            definition: "Sluggish; showing little movement or growth.",
            turkishMeaning: "durgun, hareketsiz",
            examples: [
                "With few new jobs created, the economy has remained stagnant.",
                "Stagnant water breeds mosquitoes.",
                "Her career has been stagnant for years.",
                "Sales have stagnated.",
                "The talks became stagnant."
            ],
            level: .c1, topics: [.business]
        ),
        CommonWord(
            term: "strategy",
            partOfSpeech: "noun",
            ipa: "/ˈstrætədʒi/",
            countability: "countable",
            definition: "A plan to reach a desired outcome.",
            turkishMeaning: "strateji",
            examples: [
                "The football team will need a good strategy to win the game tomorrow.",
                "We need a new marketing strategy.",
                "Her strategy paid off.",
                "What's your strategy for success?",
                "The general devised a brilliant strategy."
            ],
            level: .b2, topics: [.business]
        ),
        CommonWord(
            term: "subsequent",
            partOfSpeech: "adjective",
            ipa: "/ˈsʌbsɪkwənt/",
            countability: "N/A",
            definition: "Coming after something in time.",
            turkishMeaning: "sonraki, ardından gelen",
            examples: [
                "The first king was good, but subsequent kings have been corrupt.",
                "Subsequent events proved her right.",
                "All subsequent meetings were canceled.",
                "There were subsequent updates.",
                "Subsequent research confirmed the findings."
            ],
            level: .c1, topics: [.academic]
        ),
        CommonWord(
            term: "substitute",
            partOfSpeech: "noun",
            ipa: "/ˈsʌbstɪtjuːt/",
            countability: "countable",
            definition: "A person or thing acting in place of another.",
            turkishMeaning: "yedek, ikame",
            examples: [
                "If you don't have sugar, honey makes a good substitute.",
                "We had a substitute teacher today.",
                "There's no substitute for hard work.",
                "Use butter as a substitute for oil.",
                "She came in as a substitute on the team."
            ],
            level: .b2, topics: [.general]
        ),
        CommonWord(
            term: "subtle",
            partOfSpeech: "adjective",
            ipa: "/ˈsʌtl/",
            countability: "N/A",
            definition: "Difficult to notice right away.",
            turkishMeaning: "ince, hafif",
            examples: [
                "Maya's perfume was very subtle; you had to get close to her to smell it.",
                "There's a subtle difference between the two.",
                "She gave a subtle hint.",
                "His humor is subtle but sharp.",
                "Use subtle colors in this room."
            ],
            level: .c1, topics: [.general]
        ),
        CommonWord(
            term: "sufficient",
            partOfSpeech: "adjective",
            ipa: "/səˈfɪʃnt/",
            countability: "N/A",
            definition: "Enough to serve a particular purpose.",
            turkishMeaning: "yeterli",
            examples: [
                "Make sure you have sufficient food for the camping trip.",
                "We have sufficient evidence.",
                "Is your salary sufficient?",
                "There was sufficient time to finish.",
                "Sufficient sleep is essential."
            ],
            level: .b2, topics: [.general]
        ),
        CommonWord(
            term: "summarize",
            partOfSpeech: "verb",
            ipa: "/ˈsʌməraɪz/",
            countability: "N/A",
            definition: "To briefly give the main points.",
            turkishMeaning: "özetlemek",
            examples: [
                "The class didn't have time to read the book, so the professor summarized it.",
                "Can you summarize the article?",
                "Let me summarize what we've discussed.",
                "She summarized the report in three sentences.",
                "He summarized the meeting in an email."
            ],
            level: .b2, topics: [.academic]
        ),
        CommonWord(
            term: "supervise",
            partOfSpeech: "verb",
            ipa: "/ˈsuːpəvaɪz/",
            countability: "N/A",
            definition: "To oversee work or a process.",
            turkishMeaning: "denetlemek, gözetlemek",
            examples: [
                "My dad supervised us when we built the fort.",
                "She supervises a team of ten.",
                "Children must be supervised at the pool.",
                "The teacher supervised the exam.",
                "I supervised the construction work."
            ],
            level: .b2, topics: [.work]
        ),
        CommonWord(
            term: "supplant",
            partOfSpeech: "verb",
            ipa: "/səˈplɑːnt/",
            countability: "N/A",
            definition: "To take the place of something else.",
            turkishMeaning: "yerini almak, devralmak",
            examples: [
                "The king was supplanted by his treacherous younger brother.",
                "New technology supplants the old.",
                "She supplanted him as team leader.",
                "Streaming has supplanted DVDs.",
                "Electric cars may supplant gas vehicles."
            ],
            level: .c2, topics: [.business]
        ),
        CommonWord(
            term: "suspend",
            partOfSpeech: "verb",
            ipa: "/səˈspɛnd/",
            countability: "N/A",
            definition: "To temporarily stop, or to hang from something.",
            turkishMeaning: "askıya almak, asmak",
            examples: [
                "The power outage suspended the school concert.",
                "The lamp is suspended from the ceiling.",
                "Talks were suspended indefinitely.",
                "He was suspended from school.",
                "Service is suspended until further notice."
            ],
            level: .c1, topics: [.general]
        ),
        CommonWord(
            term: "suspicious",
            partOfSpeech: "adjective",
            ipa: "/səˈspɪʃəs/",
            countability: "N/A",
            definition: "Having the belief that someone is doing something dishonest.",
            turkishMeaning: "şüpheli, kuşkulu",
            examples: [
                "The couple became suspicious when they saw strangers in their neighbor's house.",
                "His behavior is suspicious.",
                "She gave him a suspicious look.",
                "Be suspicious of deals that seem too good.",
                "Police are treating it as a suspicious death."
            ],
            level: .b2, topics: [.emotions]
        ),
        CommonWord(
            term: "sustain",
            partOfSpeech: "verb",
            ipa: "/səˈsteɪn/",
            countability: "N/A",
            definition: "To keep going; to maintain over time.",
            turkishMeaning: "sürdürmek, ayakta tutmak",
            examples: [
                "I stopped trying to sustain the friendship after he made fun of me.",
                "The economy can't sustain such growth forever.",
                "She sustained serious injuries.",
                "Hope sustained him through hard times.",
                "We can't sustain this pace."
            ],
            level: .c1, topics: [.business]
        ),
        CommonWord(
            term: "symbolic",
            partOfSpeech: "adjective",
            ipa: "/sɪmˈbɒlɪk/",
            countability: "N/A",
            definition: "Serving as a symbol.",
            turkishMeaning: "sembolik, simgesel",
            examples: [
                "A cross is symbolic of Christianity.",
                "The gesture was purely symbolic.",
                "Red roses are symbolic of love.",
                "His resignation was symbolic.",
                "It was a symbolic victory."
            ],
            level: .c1, topics: [.general]
        ),
        CommonWord(
            term: "technical",
            partOfSpeech: "adjective",
            ipa: "/ˈtɛknɪkl/",
            countability: "N/A",
            definition: "Relating to a specific subject or craft.",
            turkishMeaning: "teknik",
            examples: [
                "The laptop manual is full of technical terms only a computer expert can understand.",
                "She has technical expertise.",
                "It's a technical problem.",
                "He provides technical support.",
                "The job requires technical skills."
            ],
            level: .b2, topics: [.technology]
        ),
        CommonWord(
            term: "terminal",
            partOfSpeech: "adjective",
            ipa: "/ˈtɜːmɪnl/",
            countability: "N/A",
            definition: "Situated at the end; final.",
            turkishMeaning: "son, terminal",
            examples: [
                "Everyone on the train must get off at the terminal stop.",
                "She was diagnosed with terminal cancer.",
                "We arrived at the terminal building.",
                "The flight departs from terminal three.",
                "His illness reached the terminal stage."
            ],
            level: .c1, topics: [.travel, .health]
        ),
        CommonWord(
            term: "tolerate",
            partOfSpeech: "verb",
            ipa: "/ˈtɒləreɪt/",
            countability: "N/A",
            definition: "To put up with something.",
            turkishMeaning: "tahammül etmek, hoşgörmek",
            examples: [
                "I tolerate the rude man since he is my husband's best friend.",
                "I can't tolerate this noise.",
                "She doesn't tolerate lying.",
                "Plants tolerate drought differently.",
                "We must tolerate different opinions."
            ],
            level: .b2, topics: [.general]
        ),
        CommonWord(
            term: "transfer",
            partOfSpeech: "verb",
            ipa: "/trænsˈfɜː/",
            countability: "N/A",
            definition: "To move from one place to another.",
            turkishMeaning: "transfer etmek, nakletmek",
            examples: [
                "Ben's work is going to transfer him from Chicago to Detroit.",
                "I transferred money to my savings account.",
                "Please transfer the call to my office.",
                "Knowledge can be transferred to new contexts.",
                "He transferred to a different university."
            ],
            level: .b2, topics: [.business]
        ),
        CommonWord(
            term: "transition",
            partOfSpeech: "noun",
            ipa: "/trænˈzɪʃn/",
            countability: "countable",
            definition: "Changing from one state to another.",
            turkishMeaning: "geçiş, dönüşüm",
            examples: [
                "The transition from student to employee can often take a while to get used to.",
                "We're in a period of transition.",
                "The transition was smooth.",
                "Climate transition is a global issue.",
                "She handled the transition gracefully."
            ],
            level: .c1, topics: [.business]
        ),
        CommonWord(
            term: "transparent",
            partOfSpeech: "adjective",
            ipa: "/trænsˈpærənt/",
            countability: "N/A",
            definition: "See-through; easy to perceive or detect.",
            turkishMeaning: "şeffaf, saydam",
            examples: [
                "The glass vase is completely transparent.",
                "Her attempt to flatter the movie star was very transparent.",
                "We value transparent communication.",
                "His lies were transparent.",
                "The company aims to be transparent with customers."
            ],
            level: .c1, topics: [.general]
        ),
        CommonWord(
            term: "tuition",
            partOfSpeech: "noun",
            ipa: "/tjuːˈɪʃn/",
            countability: "uncountable",
            definition: "The fee for instruction at a school.",
            turkishMeaning: "okul ücreti, öğretim",
            examples: [
                "College tuition prices have gone up in recent decades.",
                "She works to pay her tuition.",
                "Private school tuition is expensive.",
                "Tuition fees rise every year.",
                "He received tuition in piano."
            ],
            level: .c1, topics: [.academic]
        ),
        CommonWord(
            term: "unobtrusive",
            partOfSpeech: "adjective",
            ipa: "/ˌʌnəbˈtruːsɪv/",
            countability: "N/A",
            definition: "Not attracting attention.",
            turkishMeaning: "göze çarpmayan, mütevazı",
            examples: [
                "The prince's bodyguards had mastered the art of being unobtrusive.",
                "The decor is tasteful and unobtrusive.",
                "She has an unobtrusive personality.",
                "The cameras are unobtrusive.",
                "He gave unobtrusive support."
            ],
            level: .c2, topics: [.general]
        ),
        CommonWord(
            term: "unscathed",
            partOfSpeech: "adjective",
            ipa: "/ʌnˈskeɪðd/",
            countability: "N/A",
            definition: "Unharmed; not damaged or injured.",
            turkishMeaning: "zarar görmemiş, sağlam",
            examples: [
                "Ian was lucky to walk away from the car crash unscathed.",
                "The building emerged unscathed from the storm.",
                "She escaped the scandal unscathed.",
                "He came out unscathed despite the chaos.",
                "Few survived completely unscathed."
            ],
            level: .c2, topics: [.general]
        ),
        CommonWord(
            term: "upbeat",
            partOfSpeech: "adjective",
            ipa: "/ˌʌpˈbiːt/",
            countability: "N/A",
            definition: "Happy and optimistic.",
            turkishMeaning: "neşeli, iyimser",
            examples: [
                "Even when she's having a bad day, my mom always has an upbeat attitude.",
                "The song has an upbeat tempo.",
                "The mood was upbeat at the party.",
                "He gave an upbeat report on sales.",
                "She remains upbeat despite challenges."
            ],
            level: .c1, topics: [.emotions]
        ),
        CommonWord(
            term: "unjust",
            partOfSpeech: "adjective",
            ipa: "/ʌnˈdʒʌst/",
            countability: "N/A",
            definition: "Unfair.",
            turkishMeaning: "adaletsiz, haksız",
            examples: [
                "I felt my teacher's criticism of me was unjust.",
                "The verdict was unjust.",
                "She fought against unjust laws.",
                "It's unjust to blame him alone.",
                "An unjust system harms everyone."
            ],
            level: .c1, topics: [.general]
        ),
        CommonWord(
            term: "vacillate",
            partOfSpeech: "verb",
            ipa: "/ˈvæsɪleɪt/",
            countability: "N/A",
            definition: "To waver or be indecisive.",
            turkishMeaning: "tereddüt etmek, kararsız kalmak",
            examples: [
                "She vacillated between the two dresses.",
                "He vacillated about the job offer.",
                "Don't vacillate — choose now.",
                "Prices vacillate during the day.",
                "Her opinions vacillate constantly."
            ],
            level: .c2, topics: [.emotions]
        ),
        CommonWord(
            term: "valid",
            partOfSpeech: "adjective",
            ipa: "/ˈvælɪd/",
            countability: "N/A",
            definition: "Just; well-founded; legally acceptable.",
            turkishMeaning: "geçerli, sağlam",
            examples: [
                "The soldiers had valid concerns about the battles they'd be facing.",
                "Your ticket is valid for one year.",
                "She made a valid point.",
                "Is your passport still valid?",
                "There's a valid reason for the delay."
            ],
            level: .b2, topics: [.academic]
        ),
        CommonWord(
            term: "vanish",
            partOfSpeech: "verb",
            ipa: "/ˈvænɪʃ/",
            countability: "N/A",
            definition: "To disappear quickly.",
            turkishMeaning: "kaybolmak, yok olmak",
            examples: [
                "The plane vanished behind the clouds.",
                "My keys have vanished again.",
                "The species has vanished from the area.",
                "Hope had not yet vanished.",
                "The magician vanished from the stage."
            ],
            level: .c1, topics: [.general]
        ),
        CommonWord(
            term: "vary",
            partOfSpeech: "verb",
            ipa: "/ˈvɛəri/",
            countability: "N/A",
            definition: "To be different from one another.",
            turkishMeaning: "değişmek, farklılık göstermek",
            examples: [
                "Opinions on this issue vary widely.",
                "Prices vary from store to store.",
                "The weather varies by season.",
                "Her moods vary throughout the day.",
                "Results may vary depending on use."
            ],
            level: .b2, topics: [.general]
        ),
        CommonWord(
            term: "verdict",
            partOfSpeech: "noun",
            ipa: "/ˈvɜːdɪkt/",
            countability: "countable",
            definition: "A judgement or decision.",
            turkishMeaning: "karar, hüküm",
            examples: [
                "The jury delivered a guilty verdict.",
                "We're waiting for the verdict.",
                "What's the verdict on the new restaurant?",
                "The verdict surprised everyone.",
                "Judges issued a unanimous verdict."
            ],
            level: .c1, topics: [.business]
        ),
        CommonWord(
            term: "vestige",
            partOfSpeech: "noun",
            ipa: "/ˈvɛstɪdʒ/",
            countability: "countable",
            definition: "A small trace of something that is disappearing.",
            turkishMeaning: "iz, kalıntı",
            examples: [
                "The empty castle still had a few vestiges of its former wealth.",
                "Vestiges of the ancient civilization remain.",
                "There were vestiges of hope.",
                "Not a vestige of doubt remained.",
                "Only vestiges of the old building stand."
            ],
            level: .c2, topics: [.academic]
        ),
        CommonWord(
            term: "vial",
            partOfSpeech: "noun",
            ipa: "/ˈvaɪəl/",
            countability: "countable",
            definition: "A small container used to hold liquids.",
            turkishMeaning: "küçük şişe, fiyol",
            examples: [
                "The chemist carefully filled the vial with the bubbling solution.",
                "She kept a vial of perfume in her bag.",
                "The vials were carefully labeled.",
                "He held the vial up to the light.",
                "A vial of medicine sat on the shelf."
            ],
            level: .c1, topics: [.general]
        ),
        CommonWord(
            term: "vilify",
            partOfSpeech: "verb",
            ipa: "/ˈvɪlɪfaɪ/",
            countability: "N/A",
            definition: "To speak poorly of; to slander.",
            turkishMeaning: "karalamak, kötülemek",
            examples: [
                "Mark was vilified by his angry ex-girlfriend.",
                "The media vilified him for his comments.",
                "She was vilified in the press.",
                "Don't vilify people you disagree with.",
                "Politicians often vilify opponents."
            ],
            level: .c2, topics: [.general]
        ),
        CommonWord(
            term: "voluminous",
            partOfSpeech: "adjective",
            ipa: "/vəˈljuːmɪnəs/",
            countability: "N/A",
            definition: "Taking up a lot of space; large in volume.",
            turkishMeaning: "hacimli, geniş",
            examples: [
                "The puffy wedding dress had voluminous sleeves.",
                "She has voluminous hair.",
                "He wrote voluminous notes.",
                "The voluminous report covered every detail.",
                "Voluminous skirts were fashionable then."
            ],
            level: .c2, topics: [.general]
        ),
        CommonWord(
            term: "whereas",
            partOfSpeech: "conjunction",
            ipa: "/wɛərˈæz/",
            countability: "N/A",
            definition: "On the contrary; while in contrast.",
            turkishMeaning: "oysa, halbuki",
            examples: [
                "I always save my money whereas my brother is constantly in debt.",
                "She likes coffee, whereas he prefers tea.",
                "Whereas dogs are loyal, cats are independent.",
                "He's outgoing, whereas his brother is shy.",
                "Whereas I love winter, she prefers summer."
            ],
            level: .c1, topics: [.academic]
        ),
        CommonWord(
            term: "wholly",
            partOfSpeech: "adverb",
            ipa: "/ˈhəʊlli/",
            countability: "N/A",
            definition: "Completely; entirely.",
            turkishMeaning: "tamamen, bütünüyle",
            examples: [
                "The monk is wholly devoted to his faith.",
                "She is wholly responsible for the success.",
                "I wholly agree with you.",
                "His story was wholly fictional.",
                "The decision is wholly mine."
            ],
            level: .c2, topics: [.general]
        ),
        CommonWord(
            term: "widespread",
            partOfSpeech: "adjective",
            ipa: "/ˈwaɪdsprɛd/",
            countability: "N/A",
            definition: "Occurring over a large region.",
            turkishMeaning: "yaygın, geniş çapta",
            examples: [
                "There is widespread poverty across that country.",
                "There's widespread support for the idea.",
                "Floods caused widespread damage.",
                "Widespread protests filled the city.",
                "The disease is now widespread."
            ],
            level: .c1, topics: [.general]
        ),
        CommonWord(
            term: "wilt",
            partOfSpeech: "verb",
            ipa: "/wɪlt/",
            countability: "N/A",
            definition: "To droop and become limp, especially of plants.",
            turkishMeaning: "solmak, pörsümek",
            examples: [
                "Plants will wilt if you don't water them regularly.",
                "The flowers wilted in the heat.",
                "She seemed to wilt under pressure.",
                "Lettuce wilts quickly in warm weather.",
                "His enthusiasm began to wilt."
            ],
            level: .c1, topics: [.nature]
        )
    ]
}
