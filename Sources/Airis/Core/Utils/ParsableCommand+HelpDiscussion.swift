import ArgumentParser

extension ParsableCommand {
    static func helpDiscussion(en: String, cn: String) -> String {
        let base = HelpTextFactory.text(en: en, cn: cn)
        let metadata = AirisSkillMetadata.helpBlock(for: Self.self)
        return base + "\n\n" + metadata
    }
}
