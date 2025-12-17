// Airis CLI Entry Point
#if !XCODE_BUILD
import AirisCore
#endif

@main
struct AirisMain {
    static func main() async {
        await AirisCommand.main()
    }
}
