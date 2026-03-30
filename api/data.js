export default async function handler(req, res) {
  const EC_ID = process.env.EDGE_CONFIG_ID;
  const TOKEN = process.env.VERCEL_API_TOKEN;
  const TEAM_ID = process.env.VERCEL_TEAM_ID;

  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return res.status(200).end();

  try {
    if (req.method === 'GET') {
      // Read from Edge Config - URL has format: https://edge-config.vercel.com/ecfg_xxx?token=yyy
      const ecUrl = process.env.EDGE_CONFIG;
      const url = new URL(ecUrl);
      url.pathname = url.pathname + '/items';
      const resp = await fetch(url.toString());
      const data = await resp.json();
      return res.status(200).json({
        tasks: data.tasks || [],
        team: data.team || [],
        adminPin: data.adminPin || '1234'
      });
    }

    if (req.method === 'POST') {
      const body = req.body;
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

      if (items.length === 0) {
        return res.status(400).json({ error: 'No data to save' });
      }

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
      const result = await resp.json();
      return res.status(200).json(result);
    }

    return res.status(405).json({ error: 'Method not allowed' });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}
