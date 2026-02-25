import re

text = "cd /tmp\x1b[0mls -la\n\x1b]0;title\x07pwd"
print("Input str length:", len(text))
pos = 1
while pos <= len(text):
    nextPos = text.find("\x1b", pos - 1) + 1
    if nextPos > 0:
        if nextPos > pos:
            print(f"Pushed text: {repr(text[pos-1:nextPos-1])}")
        
        typeChar = text[nextPos:nextPos+1]
        endPos = 0
        
        if typeChar == "[":
            for i in range(nextPos + 1, len(text)):
                chCode = ord(text[i])
                if chCode >= 64 and chCode <= 126:
                    endPos = i + 1
                    break
            if endPos > 0:
                pos = endPos + 1
            else:
                pos = nextPos + 1
        elif typeChar == "]":
            for j in range(nextPos + 1, len(text)):
                cCode = ord(text[j])
                if cCode == 7:
                    endPos = j + 1
                    break
                elif cCode == 27:
                    if text[j+1:j+2] == "\\":
                        endPos = j + 2
                        break
            if endPos > 0:
                pos = endPos + 1
            else:
                pos = nextPos + 1
        elif typeChar in "()":
            pos = nextPos + 3 if nextPos + 2 <= len(text) else nextPos + 1
        elif typeChar in "=>":
            pos = nextPos + 2
        else:
            pos = nextPos + 1
    else:
        print(f"Remaining text: {repr(text[pos-1:])}")
        pos = len(text) + 1

