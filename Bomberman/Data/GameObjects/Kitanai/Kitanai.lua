function Local.Init()
    stream = Hook.Console:createStream("Kitanai", true);
end

function Global.Console.UserInput(input)
    Plugins.Brainfuck("++++++++++[>+++++++>++++++++++>+++>+<<<<-]>++.>+.+++++++..+++.>++.<<+++++++++++++++.>.+++.------.--------.>+.>.");
end