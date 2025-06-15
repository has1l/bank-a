require('dotenv').config();
const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');
const OpenAI = require("openai");

const app = express();
app.use(cors());
app.use(express.json());


const db = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

const pool = db.promise(); 
db.getConnection((err, connection) => {
  if (!err) {
    connection.release();
  }
});

app.post('/login', (req, res) => {
  const { phone, password } = req.body;

  if (!phone || !password) {
    return res.status(400).json({ success: false, message: 'Введите логин и пароль' });
  }

  const query = `
    SELECT * FROM users WHERE
    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(phone, "+", ""), "(", ""), ")", ""), "-", ""), " ", "") = ?
    AND password_hash = ?
  `;
  db.query(query, [phone.replace(/\D/g, ''), password], (err, results) => {
    if (err) {
      return res.status(500).json({ success: false, message: 'Ошибка сервера' });
    }

    if (results.length > 0) {
      const user = results[0];
      if (user) {
        res.json({ success: true, message: 'Авторизация успешна', user });
      } else {
        res.status(500).json({ success: false, message: 'Пользователь не найден' });
      }
    } else {
      res.status(401).json({ success: false, message: 'Неверный логин или пароль' });
    }
  });
});

app.post('/register', (req, res) => {
  const { name, phone, password } = req.body;

  if (!name || !phone || !password) {
    return res.status(400).json({ success: false, message: 'Все поля обязательны' });
  }

  const checkQuery = `
    SELECT * FROM users WHERE 
    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(phone, "+", ""), "(", ""), ")", ""), "-", ""), " ", "") = ?
  `;
  db.query(checkQuery, [phone.replace(/\D/g, '')], (err, results) => {
    if (err) {
      return res.status(500).json({ success: false, message: 'Ошибка сервера' });
    }

    if (results.length > 0) {
      return res.status(409).json({ success: false, message: 'Пользователь уже существует' });
    }

    const insertQuery = 'INSERT INTO users (name, phone, password_hash, created_at) VALUES (?, ?, ?, NOW())';
    db.query(insertQuery, [name, phone, password], (err, result) => {
      if (err) {
        return res.status(500).json({ success: false, message: 'Ошибка сервера при регистрации' });
      }
      res.status(201).json({ success: true, message: 'Регистрация успешна' });
    });
  });
});

app.post('/check-user', (req, res) => {
  let phone = req.body.phone;
  if (!phone) {
    return res.status(400).json({ exists: false, message: 'Номер не указан' });
  }

  phone = phone.replace(/\D/g, '');
  const query = `
    SELECT * FROM users WHERE
    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(phone, "+", ""), "(", ""), ")", ""), "-", ""), " ", "") = ?
  `;
  db.query(query, [phone], (err, results) => {
    if (err) {
      return res.status(500).json({ exists: false, message: 'Ошибка сервера' });
    }

    if (results.length > 0) {
      return res.json({ exists: true, name: results[0].name });
    } else {
      return res.json({ exists: false });
    }
  });
});

app.post('/update-name', (req, res) => {
  const { phone, newName } = req.body;

  if (!phone || !newName) {
    return res.status(400).json({ success: false, message: 'Телефон и новое имя обязательны' });
  }

  const updateQuery = `
    UPDATE users SET name = ?
    WHERE REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(phone, "+", ""), "(", ""), ")", ""), "-", ""), " ", "") = ?
  `;
  db.query(updateQuery, [newName, phone.replace(/\D/g, '')], (err, result) => {
    if (err) {
      return res.status(500).json({ success: false, message: 'Ошибка сервера' });
    }
    res.json({ success: true, message: 'Имя обновлено' });
  });
});

app.get('/balance', (req, res) => {
  let phone = req.query.phone;
  if (!phone) {
    return res.status(400).json({ success: false, message: 'Номер не указан' });
  }

  phone = phone.replace(/\D/g, '');
  const query = `
    SELECT balance FROM users WHERE
    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(phone, "+", ""), "(", ""), ")", ""), "-", ""), " ", "") = ?
  `;
  db.query(query, [phone], (err, results) => {
    if (err) {
      return res.status(500).json({ success: false, message: 'Ошибка сервера' });
    }
    if (results.length > 0) {
      res.json({ success: true, balance: results[0].balance });
    } else {
      res.status(404).json({ success: false, message: 'Пользователь не найден' });
    }
  });
});

app.post('/balance', (req, res) => {
  const { phone, balance } = req.body;
  if (!phone || balance == null) {
    return res.status(400).json({ success: false, message: 'Номер и баланс обязательны' });
  }

  const updateQuery = `
    UPDATE users SET balance = ?
    WHERE REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(phone, "+", ""), "(", ""), ")", ""), "-", ""), " ", "") = ?
  `;
  db.query(updateQuery, [balance, phone.replace(/\D/g, '')], (err, result) => {
    if (err) {
      return res.status(500).json({ success: false, message: 'Ошибка сервера' });
    }
    res.json({ success: true, message: 'Баланс обновлён' });
  });
});

const openai = new OpenAI({
  apiKey: process.env.neyro,
});

app.post('/analyzeYesterday', async (req, res) => {
  const { expenses, phone } = req.body;

  try {
    const completion = await openai.chat.completions.create({
      model: "gpt-3.5-turbo",
      messages: [
        {
          role: "system",
          content: `Ты — весёлый и заботливый помощник-подросток. Ты анализируешь траты пользователя за вчера и придумываешь 3 персональных задания на завтра, а также одно общее. Учитывай категорию, подкатегорию, цель, сумму и время каждой траты. 
Если покупка еды утром — предложи завтрак дома. Если поздно вечером купил что-то онлайн — посоветуй не сидеть на маркетплейсах на ночь. Если еда — уточни была ли она в ресторане, или покупка в магазине. Если транспорт — различай между такси и метро. 
Формат ответа должен быть строго таким:
1. Задание 1 (коротко, по делу)
2. Задание 2
3. Задание 3
Совет: общий совет

Никаких вступлений, пояснений или анализа. Используй тёплый, лёгкий стиль общения, как будто ты друг, но пиши кратко.`,
        },
        {
          role: "user",
          content: `Вот список трат за вчера:\n${Array.isArray(expenses) ? expenses.map(e => 
            `Категория: ${e.category}, Подкатегория: ${e.subcategory}, Цель: ${e.purpose || 'не указана'}, Сумма: ${e.amount}₽, Время: ${e.time || 'не указано'}`
          ).join('\n') : 'Нет данных о тратах'}`,
        },
      ],
    });

    const reply = completion.choices[0].message.content;
    const adviceMatch = reply.match(/Совет[:：](.+)/i);
    const advice = adviceMatch ? adviceMatch[1].trim() : "";
    const tasks = reply
      .split('\n')
      .filter(line => line.trim().match(/^\d\.\s/))
      .map(line => line.replace(/^\d\.\s/, '').trim());
    const normalizedPhone = phone.replace(/\D/g, '');
    const taskValues = tasks.map(task => [normalizedPhone, task]);
    const taskQuery = 'INSERT INTO tasks (phone, task) VALUES ?';
    db.query(taskQuery, [taskValues], (err) => {
      if (!err) {
        const adviceQuery = 'INSERT INTO advice (phone, content) VALUES (?, ?)';
        db.query(adviceQuery, [normalizedPhone, advice], (err) => {});
      }
    });
    res.json({ tasks, advice });
  } catch (error) {
    res.status(500).json({ response: "Произошла ошибка анализа" });
  }
});


app.post('/analyzeToday', async (req, res) => {
  const { phone, expenses, tasks } = req.body;

  if (!phone || !Array.isArray(expenses) || !Array.isArray(tasks)) {
    return res.status(400).json({ success: false, message: 'Номер, траты и задания обязательны' });
  }

  try {
    const gptMessages = [
      {
        role: "system",
        content: `Ты — весёлый и заботливый помощник-подросток. Пользователь получил вчера задания, и сегодня их выполнял. Проанализируй, выполнил ли он их по тратам. Если да — ставь балл. Отвечай строго в формате:
Выполнено: X из Y
- Задание: (текст) — ✅/❌
...
Совет: (общий вывод о дне)
Не пиши лишнего, только список и совет.`
      },
      {
        role: "user",
        content: `Вот задания:\n${tasks.map(t => "- " + t).join("\n")}\n\nВот траты за сегодня:\n${expenses.map(e =>
          `Категория: ${e.category}, Подкатегория: ${e.subcategory}, Сумма: ${e.amount}₽, Время: ${e.time || 'не указано'}`
        ).join("\n")}`
      }
    ];

    const completion = await openai.chat.completions.create({
      model: "gpt-3.5-turbo",
      messages: gptMessages,
    });

    const reply = completion.choices[0].message.content;
    const match = reply.match(/Выполнено:\s*(\d+)/i);
    const completed = match ? parseInt(match[1]) : 0;
    const adviceMatch = reply.match(/Совет[:：](.+)/i);
    const advice = adviceMatch ? adviceMatch[1].trim() : "";
    const completedTasks = reply
      .split('\n')
      .filter(line => line.includes('— ✅'))
      .map(line => {
        const match = line.match(/- Задание:\s*(.+?)\s*—/);
        return match ? match[1].trim() : null;
      })
      .filter(task => task);
    const updateScore = `
      UPDATE users SET score = score + ?
      WHERE REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(phone, "+", ""), "(", ""), ")", ""), "-", ""), " ", "") = ?
    `;
    db.query(updateScore, [completed, phone.replace(/\D/g, '')], (err) => {});
    res.json({
      success: true,
      completedTasks,
      score: completedTasks.length,
      advice
    });
  } catch (err) {
    res.status(500).json({ success: false, message: "Ошибка анализа" });
  }
});


app.post('/save-analysis', (req, res) => {
  const { phone, tasks, advice } = req.body;

  if (!phone || !tasks || !advice) {
    return res.status(400).json({ success: false, message: 'Номер, задания и совет обязательны' });
  }

  const normalizedPhone = phone.replace(/\D/g, '');
  const taskValues = tasks.map(task => [normalizedPhone, task]);
  const taskQuery = 'INSERT INTO tasks (phone, task) VALUES ?';

  db.query(taskQuery, [taskValues], (err) => {
    if (err) {
      return res.status(500).json({ success: false, message: 'Ошибка при сохранении заданий' });
    }
    const adviceQuery = 'INSERT INTO advice (phone, content) VALUES (?, ?)';
    db.query(adviceQuery, [normalizedPhone, advice], (err) => {
      if (err) {
        return res.status(500).json({ success: false, message: 'Ошибка при сохранении совета' });
      }
      res.json({ success: true, message: 'Задания и совет сохранены' });
    });
  });
});

app.get('/tasks', (req, res) => {
  const phone = req.query.phone?.replace(/\D/g, '');
  if (!phone) return res.status(400).json({ success: false, message: 'Номер обязателен' });

  const query = `
    SELECT task FROM tasks
    WHERE REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(phone, "+", ""), "(", ""), ")", ""), "-", ""), " ", "") = ?
    ORDER BY created_at DESC LIMIT 3
  `;
  db.query(query, [phone], (err, results) => {
    if (err) return res.status(500).json({ success: false, message: 'Ошибка сервера' });
    const tasks = results.map(r => r.task);
    res.json({ success: true, tasks });
  });
});

app.get('/advice', (req, res) => {
  const phone = req.query.phone?.replace(/\D/g, '');
  if (!phone) return res.status(400).json({ success: false, message: 'Номер обязателен' });

  const query = `
    SELECT content FROM advice
    WHERE REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(phone, "+", ""), "(", ""), ")", ""), "-", ""), " ", "") = ?
    ORDER BY created_at DESC LIMIT 1
  `;

  db.query(query, [phone], (err, results) => {
    if (err) return res.status(500).json({ success: false, message: 'Ошибка сервера' });
    const advice = results.length > 0 ? results[0].content : '';
    res.json({ success: true, advice });
  });
});

app.get('/score', async (req, res) => {
  const phone = req.query.phone;
  if (!phone) {
    return res.status(400).json({ success: false, message: 'Номер телефона обязателен' });
  }

  try {
    const cleaned = phone.replace(/\D/g, '');
    const [rows] = await pool.query(`
      SELECT score FROM users WHERE
      REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(phone, "+", ""), "(", ""), ")", ""), "-", ""), " ", "") = ?
    `, [cleaned]);
    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Пользователь не найден' });
    }
    const score = rows[0].score ?? 0;
    res.json({ success: true, score });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Ошибка сервера' });
  }
});

app.post('/score', async (req, res) => {
  const { phone, score } = req.body;
  if (!phone || score === undefined) {
    return res.status(400).json({ success: false, message: 'Телефон и баллы обязательны' });
  }

  try {
    const cleaned = phone.replace(/\D/g, '');
    const updateQuery = `
      UPDATE users SET score = score + ?
      WHERE REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(phone, "+", ""), "(", ""), ")", ""), "-", ""), " ", "") = ?
    `;
    const [result] = await pool.query(updateQuery, [score, cleaned]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Пользователь не найден' });
    }
    const [rows] = await pool.query(`
      SELECT score FROM users WHERE
      REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(phone, "+", ""), "(", ""), ")", ""), "-", ""), " ", "") = ?
    `, [cleaned]);
    const newScore = rows[0]?.score ?? 0;
    res.json({ success: true, message: 'Баллы добавлены', score: newScore });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Ошибка сервера' });
  }
});

app.post('/resetUserData', (req, res) => {
  const rawPhone = req.body.phone;
  const phone = rawPhone?.replace(/\D/g, '');
  if (!phone) {
    return res.status(400).json({ success: false, message: 'Номер телефона обязателен' });
  }

  const deleteTasksQuery = 'DELETE FROM tasks WHERE phone = ?';
  const deleteAdviceQuery = 'DELETE FROM advice WHERE phone = ?';

  db.query(deleteTasksQuery, [phone], (err) => {
    if (err) {
      return res.status(500).json({ success: false, message: 'Ошибка при удалении заданий' });
    }
    db.query(deleteAdviceQuery, [phone], (err2) => {
      if (err2) {
        return res.status(500).json({ success: false, message: 'Ошибка при удалении совета' });
      }
      res.json({ success: true, message: 'Задания и совет удалены' });
    });
  });
});

app.post('/resetAdviceOnly', (req, res) => {
  const rawPhone = req.body.phone;
  const phone = rawPhone?.replace(/\D/g, '');

  if (!phone) {
    return res.status(400).json({ success: false, message: 'Номер телефона обязателен' });
  }

  const deleteAdviceQuery = `
    DELETE FROM advice
    WHERE REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(phone, "+", ""), "(", ""), ")", ""), "-", ""), " ", "") = ?
  `;
  db.query(deleteAdviceQuery, [phone], (err) => {
    if (err) {
      return res.status(500).json({ success: false, message: 'Ошибка при удалении совета' });
    }
    res.json({ success: true, message: 'Совет удалён' });
  });
});

app.post('/resetTasksOnly', (req, res) => {
  const rawPhone = req.body.phone;
  const phone = rawPhone?.replace(/\D/g, '');

  if (!phone) {
    return res.status(400).json({ success: false, message: 'Номер телефона обязателен' });
  }

  const deleteTasksQuery = `
    DELETE FROM tasks
    WHERE REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(phone, "+", ""), "(", ""), ")", ""), "-", ""), " ", "") = ?
  `;
  db.query(deleteTasksQuery, [phone], (err) => {
    if (err) {
      return res.status(500).json({ success: false, message: 'Ошибка при удалении заданий' });
    }
    res.json({ success: true, message: 'Задания удалены' });
  });
});

app.get('/expenses', (req, res) => {
  const phone = req.query.phone?.replace(/\D/g, '');
  const date = req.query.date;

  if (!phone || !date) {
    return res.status(400).json({ success: false, message: 'Номер и дата обязательны' });
  }

  const query = `
    SELECT category, subcategory, amount, time FROM expenses
    WHERE REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(phone, "+", ""), "(", ""), ")", ""), "-", ""), " ", "") = ?
    AND date = ?
  `;

  db.query(query, [phone, date], (err, results) => {
    if (err) return res.status(500).json({ success: false, message: 'Ошибка сервера' });
    res.json({ success: true, expenses: results });
  });
});

app.get("/boosts", async (req, res) => {
    const phone = req.query.phone;

    try {
        const cleanedPhone = phone.replace(/\D/g, '');
        const [userRows] = await pool.execute(`
          SELECT id FROM users_boost WHERE
          REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(phone, "+", ""), "(", ""), ")", ""), "-", ""), " ", "") = ?
        `, [cleanedPhone]);
        if (userRows.length === 0) {
            return res.json({ success: false, message: "Пользователь не найден" });
        }
        const userId = userRows[0].id;
        const [boosts] = await pool.execute("SELECT * FROM boosts WHERE user_id = ?", [userId]);
        res.json({ success: true, data: boosts });
    } catch (error) {
        res.status(500).json({ success: false, message: "Ошибка сервера" });
    }
});

app.post('/boost-nickname', (req, res) => {
    const { phone, nickname } = req.body;

    if (!phone || !nickname) {
        return res.status(400).json({ success: false, message: 'Нужны номер телефона и никнейм' });
    }

    const checkQuery = 'SELECT * FROM users_boost WHERE phone = ?';
    db.query(checkQuery, [phone], (err, results) => {
        if (err) {
            return res.status(500).json({ success: false, message: 'Ошибка сервера' });
        }
        if (results.length > 0) {
            const updateQuery = 'UPDATE users_boost SET nickname = ? WHERE phone = ?';
            db.query(updateQuery, [nickname, phone], (err) => {
                if (err) {
                    return res.status(500).json({ success: false, message: 'Ошибка обновления ника' });
                }
                return res.json({ success: true, message: 'Никнейм обновлён' });
            });
        } else {
            const insertQuery = 'INSERT INTO users_boost (phone, nickname) VALUES (?, ?)';
            db.query(insertQuery, [phone, nickname], (err) => {
                if (err) {
                    return res.status(500).json({ success: false, message: 'Ошибка создания пользователя' });
                }
                return res.json({ success: true, message: 'Пользователь создан' });
            });
        }
    });
});

app.post('/boosts', (req, res) => {
    const { phone, video_url, title } = req.body;
    if (!phone || !video_url) {
        return res.status(400).json({ success: false, message: 'Номер телефона и видео обязательны' });
    }

    const findUserIdQuery = 'SELECT id FROM users_boost WHERE phone = ?';
    db.query(findUserIdQuery, [phone], (err, userResults) => {
        if (err) {
            return res.status(500).json({ success: false, message: 'Ошибка сервера' });
        }
        if (userResults.length === 0) {
            return res.status(404).json({ success: false, message: 'Пользователь не найден' });
        }
        const userId = userResults[0].id;
        const insertBoostQuery = 'INSERT INTO boosts (user_id, video_url, title) VALUES (?, ?, ?)';
        db.query(insertBoostQuery, [userId, video_url, title], (err, result) => {
            if (err) {
                return res.status(500).json({ success: false, message: 'Ошибка при добавлении буста' });
            }
            res.json({ success: true, message: 'Буст добавлен' });
        });
    });
});

const PORT = process.env.PORT || 3001;
app.listen(PORT);