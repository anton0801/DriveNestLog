import SwiftUI

struct AuthView: View {
    @EnvironmentObject var appState: AppState
    @State private var showRegister = false
    
    var body: some View {
        if showRegister {
            RegisterView(showRegister: $showRegister)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
        } else {
            SignInView(showRegister: $showRegister)
                .transition(.asymmetric(
                    insertion: .move(edge: .leading),
                    removal: .move(edge: .trailing)
                ))
        }
    }
}

struct SignInView: View {
    @EnvironmentObject var appState: AppState
    @Binding var showRegister: Bool
    
    @State private var email = ""
    @State private var password = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var headerOffset: CGFloat = -30
    @State private var headerOpacity: Double = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: DNSpacing.lg) {
                // Header
                VStack(spacing: DNSpacing.sm) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient.dnBlueGradient)
                            .frame(width: 80, height: 80)
                        Image(systemName: "car.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.white)
                    }
                    .dnShadow(color: .dnAccentBlue.opacity(0.4), radius: 16)
                    
                    Text("Welcome Back")
                        .font(DNFont.display(28))
                        .foregroundColor(.dnText)
                    
                    Text("Sign in to your DriveNest account")
                        .font(DNFont.body(14))
                        .foregroundColor(.dnTextSecondary)
                }
                .padding(.top, DNSpacing.xxl)
                .offset(y: headerOffset)
                .opacity(headerOpacity)
                
                // Form
                VStack(spacing: DNSpacing.md) {
                    DNTextField(title: "Email", text: $email, icon: "envelope.fill", keyboardType: .emailAddress)
                    DNTextField(title: "Password", text: $password, icon: "lock.fill", isSecure: true)
                }
                .padding(.top, DNSpacing.sm)
                
                if showError {
                    DNAlertCard(title: "Sign In Failed", message: errorMessage, type: .danger)
                        .transition(.scale.combined(with: .opacity))
                }
                
                // Sign In Button
                DNButton("Sign In") {
                    handleSignIn()
                }
                
                // Or divider
                HStack {
                    Rectangle().fill(Color.dnBorder).frame(height: 1)
                    Text("or").font(DNFont.body(12)).foregroundColor(.dnTextSecondary).padding(.horizontal, 8)
                    Rectangle().fill(Color.dnBorder).frame(height: 1)
                }
                
                // Apple Sign In
                Button(action: { handleAppleSignIn() }) {
                    HStack(spacing: DNSpacing.sm) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 18, weight: .medium))
                        Text("Sign in with Apple")
                            .font(DNFont.heading(16))
                    }
                    .foregroundColor(.dnText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.dnCard)
                    .cornerRadius(DNRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: DNRadius.md)
                            .stroke(Color.dnBorder, lineWidth: 1)
                    )
                }
                
                // Create account
                Button(action: {
                    withAnimation(.dnSpring) { showRegister = true }
                }) {
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .foregroundColor(.dnTextSecondary)
                        Text("Create Account")
                            .foregroundColor(.dnAccentBlue)
                    }
                    .font(DNFont.body(14))
                }
                .padding(.bottom, DNSpacing.xxl)
            }
            .padding(.horizontal, DNSpacing.lg)
        }
        .background(Color.dnBackground.ignoresSafeArea())
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                headerOffset = 0
                headerOpacity = 1
            }
        }
    }
    
    private func handleSignIn() {
        guard !email.isEmpty else {
            showError = true
            errorMessage = "Please enter your email address."
            return
        }
        guard !password.isEmpty else {
            showError = true
            errorMessage = "Please enter your password."
            return
        }
        guard password.count >= 6 else {
            showError = true
            errorMessage = "Password must be at least 6 characters."
            return
        }
        
        showError = false
        isLoading = true
        
        // Simulate auth delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isLoading = false
            let success = appState.signIn(email: email, password: password)
            if !success {
                withAnimation(.dnSpring) {
                    showError = true
                    errorMessage = "Invalid credentials. Please try again."
                }
            }
        }
    }
    
    private func handleAppleSignIn() {
        // Simulate Apple Sign In
        let appleEmail = "user@icloud.com"
        _ = appState.signIn(email: appleEmail, password: "apple_token", name: "Apple User")
    }
}

struct RegisterView: View {
    @EnvironmentObject var appState: AppState
    @Binding var showRegister: Bool
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: DNSpacing.lg) {
                // Header
                VStack(spacing: DNSpacing.sm) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient.dnOrangeGradient)
                            .frame(width: 80, height: 80)
                        Image(systemName: "person.fill.badge.plus")
                            .font(.system(size: 34))
                            .foregroundColor(.white)
                    }
                    .dnShadow(color: .dnAccentOrange.opacity(0.4), radius: 16)
                    
                    Text("Create Account")
                        .font(DNFont.display(28))
                        .foregroundColor(.dnText)
                    
                    Text("Join DriveNest Log today")
                        .font(DNFont.body(14))
                        .foregroundColor(.dnTextSecondary)
                }
                .padding(.top, DNSpacing.xl)
                
                // Form
                VStack(spacing: DNSpacing.md) {
                    DNTextField(title: "Full Name", text: $name, icon: "person.fill")
                    DNTextField(title: "Email", text: $email, icon: "envelope.fill", keyboardType: .emailAddress)
                    DNTextField(title: "Password", text: $password, icon: "lock.fill", isSecure: true)
                    DNTextField(title: "Confirm Password", text: $confirmPassword, icon: "lock.shield.fill", isSecure: true)
                }
                
                if showError {
                    DNAlertCard(title: "Registration Error", message: errorMessage, type: .danger)
                        .transition(.scale.combined(with: .opacity))
                }
                
                if showSuccess {
                    DNAlertCard(title: "Account Created!", message: "Welcome to DriveNest Log.", type: .success)
                        .transition(.scale.combined(with: .opacity))
                }
                
                DNButton("Create Account", gradient: .dnOrangeGradient) {
                    handleRegister()
                }
                
                Button(action: {
                    withAnimation(.dnSpring) { showRegister = false }
                }) {
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .foregroundColor(.dnTextSecondary)
                        Text("Sign In")
                            .foregroundColor(.dnAccentBlue)
                    }
                    .font(DNFont.body(14))
                }
                .padding(.bottom, DNSpacing.xxl)
            }
            .padding(.horizontal, DNSpacing.lg)
        }
        .background(Color.dnBackground.ignoresSafeArea())
    }
    
    private func handleRegister() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            showError = true
            errorMessage = "Please enter your full name."
            return
        }
        guard email.contains("@") && email.contains(".") else {
            showError = true
            errorMessage = "Please enter a valid email address."
            return
        }
        guard password.count >= 6 else {
            showError = true
            errorMessage = "Password must be at least 6 characters."
            return
        }
        guard password == confirmPassword else {
            showError = true
            errorMessage = "Passwords do not match."
            return
        }
        
        showError = false
        withAnimation(.dnSpring) { showSuccess = true }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            _ = appState.signIn(email: email, password: password, name: name)
        }
    }
}
