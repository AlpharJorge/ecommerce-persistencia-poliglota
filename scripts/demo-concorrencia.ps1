$BaseUrl = 'http://localhost:3000/api'
$UserId = '11111111-1111-1111-1111-111111111111'
$ProductId = '10000000-0000-0000-0000-000000000003'

Invoke-RestMethod -Method Put -Uri "$BaseUrl/products/$ProductId/core" -ContentType 'application/json' -Body '{"stock":1}' | Out-Null

$body = @{
  items = @(@{ productId = $ProductId; quantity = 1 })
  paymentMethod = 'pix'
} | ConvertTo-Json -Depth 5

$jobs = 1..2 | ForEach-Object {
  Start-Job -ScriptBlock {
    param($Url, $Customer, $Payload)
    try {
      Invoke-RestMethod -Method Post -Uri "$Url/users/$Customer/checkout" -ContentType 'application/json' -Body $Payload
    } catch {
      [PSCustomObject]@{ status = [int]$_.Exception.Response.StatusCode; erro = $_.ErrorDetails.Message }
    }
  } -ArgumentList $BaseUrl, $UserId, $body
}

$jobs | Wait-Job | Receive-Job
$jobs | Remove-Job
