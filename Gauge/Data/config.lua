config = {
    zone = {
        score = {
            first = 1000,  --pts/s
            second = 5000, --pts/s
            third = 9999, --pts/s
        },
        second = 0.12, --%
        third = 0.08, --%
    },

    player = {
        speed = 0.3, --%/s
        repop = {
            size = 0.5, --%
            time = 200, --%ms
        },
        lives = {
            start = 3, --lives
            threshold = 99999999, --pts/life
        },
    },

    bonus = {
        score = 9999, --pts
        distance = 0.05, --%
        time = {
            min = 2000, --ms
            max = 7000, --ms
        }
    },

    death_wall = {
        left = {
            size = 0.02, --%
        },
        right = {
            size = 0.02, --%
        },
        middle = {
            size = {
                min = 0.08, --%
                max = 0.4, --%
            },
            speed = {
                min = 0.15, --%/s
                max = 0.25, --%/s
            },
            time = {
                min = 0, --ms
                max = 4000, --ms
            },
        }
    }
}