# User Accounts – Nation-State Lab

## 1. Overview

In the Active Directory domain `nation.local`, multiple user accounts were created to simulate a realistic enterprise environment. These accounts represent different privilege levels and operational roles, enabling demonstrations of authentication, authorization, privilege escalation, credential theft, and lateral movement during attack simulations.

All custom user accounts are stored within the `Users` Organizational Unit (OU). Built-in Active Directory accounts remain in the default Users container.

---

## 2. User Account Details

| Username | Full Name | UPN | Password | Member Of | OU | Primary Purpose |
|-----------|------------|-----|----------|------------|-----|----------------|
| `normaluser` | Normal User | `normaluser@nation.local` | `P@ssw0rd123!` | Domain Users | Users | Standard workstation user for WS1 |
| `developer` | Developer | `developer@nation.local` | `Dev@Pass456!` | Domain Users | Users | Developer account intended for WS2 |
| `service_account` | Service Account | `service_account@nation.local` | `Svc@ccount123!` | Domain Users | Users | Service-related account for WS3 |
| `Administrator` | Administrator | `Administrator@nation.local` | `Windows_DC_Admin123!` | Domain Admins, Enterprise Admins, Schema Admins | Built-in Users | Domain administration |
| `Guest` | Guest | `Guest@nation.local` | Disabled | Domain Guests | Built-in Users | Disabled account |
| `krbtgt` | Key Distribution Center Service Account | `krbtgt@nation.local` | Managed by Active Directory | Domain Users | Built-in Users | Kerberos service account |

---

## 3. Account Creation Procedure

User accounts were created using **Active Directory Users and Computers (ADUC)**.

### Steps

1. Open **Active Directory Users and Computers**.
2. Expand:

```text
nation.local
```

3. Navigate to:

```text
Users OU
```

4. Right-click the OU and select:

```text
New → User
```

5. Enter:
   - First Name
   - Last Name
   - User Logon Name

6. Configure password settings:
   - Set password
   - Uncheck "User must change password at next logon"

7. Click **Finish**.

The built-in `Administrator` account already existed and only required password configuration.

---

## 4. Group Memberships

| Account | Built-in Groups | Custom Groups | Administrative Rights |
|----------|----------------|---------------|----------------------|
| `normaluser` | Domain Users | None | No |
| `developer` | Domain Users | None | Intended local admin on WS2 |
| `service_account` | Domain Users | None | No |
| `Administrator` | Domain Admins, Enterprise Admins, Schema Admins | None | Full administrative access |

No custom Active Directory security groups were created.

---

## 5. Account Usage During Attack Simulation

| Account | Attack Phase | Activity |
|----------|-------------|-----------|
| `normaluser` | Initial Access | Reverse shell execution on WS1 |
| `Administrator` | Credential Theft | Credential extraction from LSASS |
| `Administrator` | Lateral Movement | Pass-the-Hash authentication to DC |
| `developer` | Not Used | Present for realism |
| `service_account` | Not Used | Associated workstation removed |

---

## 6. Password Policy

The environment uses the default domain password policy.

### Configuration

| Setting | Value |
|----------|---------|
| Minimum Password Length | 7 Characters |
| Password Complexity | Enabled |
| Password History | 24 Passwords |
| Maximum Password Age | 42 Days |
| Account Lockout Threshold | 0 |

---

## 7. Security Considerations

### normaluser

- Low-privilege account
- Represents a realistic phishing victim
- Cannot perform administrative actions

### developer

- Intended to simulate a user with elevated workstation permissions
- Potential target for privilege escalation

### service_account

- Simulates service-related identities
- Useful for demonstrating service account abuse scenarios

### Administrator

- Holds full domain privileges
- High-value target during attack simulations
- Used to demonstrate credential theft and lateral movement

---

## 8. Decommissioned Accounts

### service_account

- Remains active in Active Directory
- Associated workstation (WS3) removed from lab

### developer

- Account remains active
- Associated workstation (WS2) not used in final attack chain

No accounts were deleted during the project.

---

## 9. Verification Commands

### List Domain Users

```cmd
net user /domain
```

### Display User Information

```cmd
net user normaluser /domain
```

### Display Administrator Details

```cmd
net user Administrator /domain
```

### Query Active Directory Users

```cmd
dsquery user -name * -limit 0
```

---

## 10. User Hierarchy

```text
nation.local
│
├── Administrator
│   └── Domain Admin
│
├── normaluser
│   └── Standard User
│
├── developer
│   └── Developer Account
│
├── service_account
│   └── Service Account
│
├── Guest
│   └── Disabled
│
└── krbtgt
    └── Kerberos Service Account
```

---

## 11. Lessons Learned

### Low-Privilege Users

Most attacks begin with compromise of standard user accounts. Additional privilege escalation techniques are typically required to gain administrative access.

### Administrative Accounts

Domain administrator credentials represent the most valuable target in Active Directory environments.

### Service Accounts

Service accounts frequently possess excessive privileges and can become a major attack vector if improperly managed.

---

## 12. Summary

| Category | Count |
|-----------|--------|
| Custom User Accounts | 3 |
| Built-in Administrative Accounts | 1 |
| Built-in Service Accounts | 1 |
| Disabled Accounts | 1 |
| Total Accounts Present | 6 |

The user account structure provides a realistic representation of a small enterprise Active Directory environment and supports attack simulation, detection engineering, and security monitoring activities throughout the Nation-State Lab project.