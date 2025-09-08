#!/bin/bash

# Post-deployment setup wizard completion script
# Run this after ./deploy.sh completes successfully

echo "🚀 Completing ERPNext setup wizard post-deployment..."

# Wait for site to be accessible
echo "⏳ Waiting for site to be accessible..."
until curl -s -o /dev/null -w "%{http_code}" http://intralogistics.lab/login | grep -E "200|302"; do
  echo "Waiting for site to respond..."
  sleep 5
done

echo "✅ Site is accessible, logging in as Administrator..."

# Login and get session
curl -c cookies.txt -X POST -H "Content-Type: application/json" \
  -d '{"cmd":"login","usr":"Administrator","pwd":"admin"}' \
  http://intralogistics.lab/api/method/login

sleep 2

echo "🔧 Completing setup wizard..."

# Complete setup wizard
RESPONSE=$(curl -s -b cookies.txt -X POST -H "Content-Type: application/json" \
  -d '{"cmd":"frappe.desk.page.setup_wizard.setup_wizard.setup_complete","args":{"language":"en","country":"United States","timezone":"America/New_York","currency":"USD","full_name":"Administrator","email":"admin@intralogistics.lab"}}' \
  http://intralogistics.lab/api/method/frappe.desk.page.setup_wizard.setup_wizard.setup_complete)

echo "📝 Setup wizard response: $RESPONSE"

if echo "$RESPONSE" | grep -q '"status":"ok"'; then
  echo "✅ Setup wizard completed successfully!"
  echo "🌐 You can now access ERPNext at: http://intralogistics.lab"
  echo "🔑 Login with: Administrator / admin"
else
  echo "⚠️  Setup wizard may have already been completed or there was an issue"
  echo "🌐 Try accessing: http://intralogistics.lab"
fi

# Install EpiBus app
echo "📦 Installing EpiBus app..."
docker exec intralogisticsai-backend-1 bench --site intralogistics.lab install-app epibus

# Clean up cookies file
rm -f cookies.txt

echo "🎉 Post-deployment setup complete!"