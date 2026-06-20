import Foundation

public enum WelcomeDocument {
    public static let text = """
    # Welcome to LeafMark

    LeafMark is a lightweight local Markdown editor for macOS.

    ## Try common Markdown

    - Edit on the left
    - Preview on the right
    - Save when you are ready

    > A quiet local tool for writing and reading Markdown.

    [OpenAI](https://openai.com)

    | Feature | Status |
    | --- | --- |
    | Tables | Supported |
    | Links | Supported |
    | Images | Supported |

    ```swift
    let leaf = "mark"
    print(leaf)
    ```
    """
}
