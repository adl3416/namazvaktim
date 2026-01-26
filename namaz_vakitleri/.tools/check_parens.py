path = 'lib/screens/home_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    depth = 0
    brace = 0
    bracket = 0
    for lineno, line in enumerate(f, start=1):
        for ch in line:
            if ch == '(':
                depth += 1
            elif ch == ')':
                depth -= 1
            elif ch == '{':
                brace += 1
            elif ch == '}':
                brace -= 1
            elif ch == '[':
                bracket += 1
            elif ch == ']':
                bracket -= 1
            if depth < 0 or brace < 0 or bracket < 0:
                print(f"Negative depth at line {lineno}: depth={depth}, brace={brace}, bracket={bracket}")
                raise SystemExit(1)
        # Print depths at key lines
        if lineno % 50 == 0:
            print(f"line {lineno}: depth={depth}, brace={brace}, bracket={bracket}")
    print('final counts -> paren:', depth, 'brace:', brace, 'bracket:', bracket)
