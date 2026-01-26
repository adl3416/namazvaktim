path = 'lib/screens/home_screen.dart'
stack = []
with open(path, 'r', encoding='utf-8') as f:
    for lineno, line in enumerate(f, start=1):
        for idx, ch in enumerate(line, start=1):
            if ch == '(':
                stack.append((lineno, idx, line.rstrip('\n')))
            elif ch == ')':
                if stack:
                    stack.pop()
                else:
                    print(f"Unmatched closing paren at {lineno}:{idx}")
                    raise SystemExit(1)
if stack:
    print('Unmatched opening parens (most recent first):')
    print('Total unmatched:', len(stack))
    print('stack sample repr:', repr(stack[-1]))
    # print last 20 unmatched openings for context
    for item in stack[-20:]:
        lineno, idx, line = item
        print(f"  open at {lineno}:{idx} -> {line}")
else:
    print('All parentheses matched')
