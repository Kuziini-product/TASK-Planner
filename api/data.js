export default async function handler(req, res) {
  const EC_ID = process.env.EDGE_CONFIG_ID;
  const TOKEN = process.env.VERCEL_API_TOKEN;
  const TEAM_ID = process.env.VERCEL_TEAM_ID;

  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return res.status(200).end();

  // Helper: read current data from Edge Config
  async function readData() {
    const ecUrl = process.env.EDGE_CONFIG;
    const url = new URL(ecUrl);
    url.pathname = url.pathname + '/items';
    const resp = await fetch(url.toString());
    return await resp.json();
  }

  // Helper: write items to Edge Config
  async function writeItems(items) {
    const resp = await fetch(
      `https://api.vercel.com/v1/edge-config/${EC_ID}/items?teamId=${TEAM_ID}`,
      {
        method: 'PATCH',
        headers: {
          'Authorization': `Bearer ${TOKEN}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ items }),
      }
    );
    return await resp.json();
  }

  try {
    if (req.method === 'GET') {
      const data = await readData();
      return res.status(200).json({
        tasks: data.tasks || [],
        team: data.team || [],
        adminPin: data.adminPin || '1234',
        customStatuses: data.customStatuses || [],
        activities: data.activities || []
      });
    }

    if (req.method === 'POST') {
      const body = req.body;

      // Atomic operations on tasks
      if (body.action) {
        const data = await readData();
        let tasks = data.tasks || [];

        if (body.action === 'addTask') {
          tasks.push(body.task);
        }
        else if (body.action === 'updateTask') {
          const idx = tasks.findIndex(t => t.id === body.task.id);
          if (idx !== -1) tasks[idx] = { ...tasks[idx], ...body.task };
        }
        else if (body.action === 'deleteTask') {
          tasks = tasks.filter(t => t.id !== body.taskId);
        }

        const result = await writeItems([
          { operation: 'upsert', key: 'tasks', value: tasks }
        ]);
        return res.status(200).json({ status: 'ok', tasks });
      }

      // Bulk write (for team, pin, activities, statuses, full tasks override)
      const items = [];
      if (body.tasks !== undefined) {
        items.push({ operation: 'upsert', key: 'tasks', value: body.tasks });
      }
      if (body.team !== undefined) {
        items.push({ operation: 'upsert', key: 'team', value: body.team });
      }
      if (body.adminPin !== undefined) {
        items.push({ operation: 'upsert', key: 'adminPin', value: body.adminPin });
      }
      if (body.customStatuses !== undefined) {
        items.push({ operation: 'upsert', key: 'customStatuses', value: body.customStatuses });
      }
      if (body.activities !== undefined) {
        items.push({ operation: 'upsert', key: 'activities', value: body.activities });
      }

      if (items.length === 0) {
        return res.status(400).json({ error: 'No data to save' });
      }

      const result = await writeItems(items);
      return res.status(200).json(result);
    }

    return res.status(405).json({ error: 'Method not allowed' });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}
